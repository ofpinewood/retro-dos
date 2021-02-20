#!/bin/bash

# This file is part of RetroDos
#
# RetroDos front-end for RetroPie
# RetroDos is a front-end for the RetroPie project. It's a bash script that displays menus.
#
# Author:         Peter van den Hout
# Website:        https://github.com/ofpinewood/retro-dos
# License:        MIT License (https://github.com/ofpinewood/retro-dos/master/LICENSE.md)
#

## @fn printMsgs()
## @param type style of display to use - dialog, console or heading
## @param message string or array of messages to display
## @brief Prints messages in a variety of ways.
function printMsgs() {
    local type="$1"
    shift
    if [[ "$__nodialog" == "1" && "$type" == "dialog" ]]; then
        type="console"
    fi
    for msg in "$@"; do
        [[ "$type" == "dialog" ]] && dialog --backtitle "$__backtitle" --cr-wrap --no-collapse --msgbox "$msg" 20 60 >/dev/tty
        [[ "$type" == "console" ]] && echo -e "$msg"
        [[ "$type" == "heading" ]] && echo -e "\n= = = = = = = = = = = = = = = = = = = = =\n$msg\n= = = = = = = = = = = = = = = = = = = = =\n"
    done
    return 0
}

## @fn printHeading()
## @param message string or array of messages to display
## @brief Calls PrintMsgs with "heading" type.
function printHeading() {
    printMsgs "heading" "$@"
}

## @fn fatalError()
## @param message string or array of messages to display
## @brief Calls PrintMsgs with "heading" type, and exits immediately.
function fatalError() {
    printHeading "Error"
    echo -e "$1"
    exit 1
}

# @fn fnExists()
# @param name name of function to check for
# @brief Checks if function name exists.
# @retval 0 if the function name exists
# @retval 1 if the function name does not exist
function fnExists() {
    declare -f "$1" > /dev/null
    return $?
}

## @fn hasFlag()
## @param string string to search in
## @param flag flag to search for
## @brief Checks for a flag in a string (consisting of space separated flags).
## @retval 0 if the flag was found
## @retval 1 if the flag was not found
function hasFlag() {
    local string="$1"
    local flag="$2"
    [[ -z "$string" || -z "$flag" ]] && return 1

    if [[ "$string" =~ (^| )$flag($| ) ]]; then
        return 0
    else
        return 1
    fi
}

## @fn isPlatform()
## @param platform
## @brief Test for current platform / platform flags.
function isPlatform() {
    local flag="$1"
    if hasFlag "${__platform_flags[*]}" "$flag"; then
        return 0
    fi
    return 1
}

# @fn setupDirectories()
# @brief Makes sure some required retropie directories and files are created.
function setupDirectories() {
    mkdir -p "$rootdir"
    mkUserDir "$romdir"

    # some home folders for configs that modules rely on
    mkUserDir "$home/.cache"
    mkUserDir "$home/.config"
    mkUserDir "$home/.local"
    mkUserDir "$home/.local/share"

    # make sure we have inifuncs.sh in place and that it is up to date
    # mkdir -p "$rootdir/lib"
    # local helper_libs=(inifuncs.sh archivefuncs.sh)
    # for helper in "${helper_libs[@]}"; do
    #     if [[ ! -f "$rootdir/lib/$helper" || "$rootdir/lib/$helper" -ot "$scriptdir/scriptmodules/$helper" ]]; then
    #         cp --preserve=timestamps "$scriptdir/scriptmodules/$helper" "$rootdir/lib/$helper"
    #     fi
    # done

    # # create template for autoconf.cfg and make sure it is owned by $user
    # local config="$configdir/all/autoconf.cfg"
    # if [[ ! -f "$config" ]]; then
    #     echo "# this file can be used to enable/disable retropie autoconfiguration features" >"$config"
    # fi
    # chown $user:$user "$config"
}

## @fn mkUserDir()
## @param dir directory to create
## @brief Creates a directory owned by the current user.
function mkUserDir() {
    mkdir -p "$1"
    chown $user:$user "$1"
}

## @fn setConfigRoot()
## @param dir directory under $configdir to use
## @brief Sets module config root `$md_conf_root` to subfolder from `$configdir`
## @details This is used for ports that are not actually in scriptmodules/ports
## as they would get the wrong config root otherwise.
function setConfigRoot() {
    local dir="$1"
    md_conf_root="$configdir"
    [[ -n "$dir" ]] && md_conf_root+="/$dir"
    mkUserDir "$md_conf_root"
}

## @fn getDepends()
## @param packages package / space separated list of packages to install
## @brief Installs packages if they are not installed.
## @retval 0 on success
## @retval 1 on failure
function getDepends() {
    local own_pkgs=()
    local apt_pkgs=()
    local all_pkgs=()
    local pkg
    for pkg in "$@"; do
        pkg=($(_mapPackage "$pkg"))
        # manage our custom packages (pkg = "RP module_id pkg_name")
        if [[ "${pkg[0]}" == "RP" ]]; then
            # if removing, check if any version is installed and queue for removal via the custom module
            if [[ "$md_mode" == "remove" ]]; then
                if hasPackage "${pkg[2]}"; then
                    own_pkgs+=("${pkg[1]}")
                    all_pkgs+=("${pkg[2]}(custom)")
                fi
            else
                # if installing check if our version is installed and queue for installing via the custom module
                if hasPackage "${pkg[2]}" $(get_pkg_ver_${pkg[1]}) "ne"; then
                    own_pkgs+=("${pkg[1]}")
                    all_pkgs+=("${pkg[2]}(custom)")
                fi
            fi
            continue
        fi

        if [[ "$md_mode" == "remove" ]]; then
            # add package to apt_pkgs for removal if installed
            if hasPackage "$pkg"; then
                apt_pkgs+=("$pkg")
                all_pkgs+=("$pkg")
            fi
        else
            # add package to apt_pkgs for installation if not installed
            if ! hasPackage "$pkg"; then
                apt_pkgs+=("$pkg")
                all_pkgs+=("$pkg")
            fi
        fi

    done


    # return if no packages required
    [[ ${#apt_pkgs[@]} -eq 0 && ${#own_pkgs[@]} -eq 0 ]] && return

    # if we are removing, then remove packages, do an autoremove to clean up additional packages and return
    if [[ "$md_mode" == "remove" ]]; then
        printMsgs "console" "Removing dependencies: ${all_pkgs[*]}"
        for pkg in ${own_pkgs[@]}; do
            rp_callModule "$pkg" remove
        done
        apt-get remove --purge -y "${apt_pkgs[@]}"
        apt-get autoremove --purge -y
        return 0
    fi

    printMsgs "console" "Did not find needed dependencies: ${all_pkgs[*]}. Trying to install them now."

    # install any custom packages
    for pkg in ${own_pkgs[@]}; do
       rp_callModule "$pkg" _auto_
    done

    aptInstall --no-install-recommends "${apt_pkgs[@]}"

    local failed=()
    # check the required packages again rather than return code of apt-get,
    # as apt-get might fail for other reasons (eg other half installed packages)
    for pkg in ${apt_pkgs[@]}; do
        if ! hasPackage "$pkg"; then
            # workaround for installing samba in a chroot (fails due to failed smbd service restart)
            # we replace the init.d script with an empty script so the install completes
            if [[ "$pkg" == "samba" && "$__chroot" -eq 1 ]]; then
                mv /etc/init.d/smbd /etc/init.d/smbd.old
                echo "#!/bin/sh" >/etc/init.d/smbd
                chmod u+x /etc/init.d/smbd
                apt-get -f install
                mv /etc/init.d/smbd.old /etc/init.d/smbd
            else
                failed+=("$pkg")
            fi
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        md_ret_errors+=("Could not install package(s): ${failed[*]}.")
        return 1
    fi

    return 0
}

## @fn hasPackage()
## @param package name of Debian package
## @param version requested version (optional)
## @param comparison type of comparison - defaults to `ge` (greater than or equal) if a version parameter is provided.
## @brief Test for an installed Debian package / package version.
## @retval 0 if the requested package / version was installed
## @retval 1 if the requested package / version was not installed
function hasPackage() {
    local pkg="$1"
    local req_ver="$2"
    local comp="$3"
    [[ -z "$comp" ]] && comp="ge"

    local ver
    local status
    local out=$(dpkg-query -W --showformat='${Status} ${Version}' $1 2>/dev/null)
    if [[ "$?" -eq 0 ]]; then
        ver="${out##* }"
        status="${out% *}"
    fi

    local installed=0
    [[ "$status" == *"ok installed" ]] && installed=1
    # if we are not checking version
    if [[ -z "$req_ver" ]]; then
        # if the package is installed return true
        [[ "$installed" -eq 1 ]] && return 0
    else
        # if checking version and the package is not installed we need to clear "ver" as it may contain
        # the version number of a removed package and give a false positive with compareVersions.
        # we still need to do the version check even if not installed due to the varied boolean operators
        [[ "$installed" -eq 0 ]] && ver=""

        compareVersions "$ver" "$comp" "$req_ver" && return 0
    fi
    return 1
}

## @fn aptUpdate()
## @brief Calls apt-get update (if it has not been called before).
function aptUpdate() {
    if [[ "$__apt_update" != "1" ]]; then
        apt-get update
        __apt_update="1"
    fi
}

## @fn aptInstall()
## @param packages package / space separated list of packages to install
## @brief Calls apt-get install with the packages provided.
function aptInstall() {
    aptUpdate
    apt-get install -y "$@"
    return $?
}

## @fn aptRemove()
## @param packages package / space separated list of packages to install
## @brief Calls apt-get remove with the packages provided.
function aptRemove() {
    aptUpdate
    apt-get remove -y "$@"
    return $?
}

## @fn compareVersions()
## @param version first version to compare
## @param operator operator to use (lt le eq ne ge gt)
## @brief version second version to compare
## @retval 0 if the comparison was true
## @retval 1 if the comparison was false
function compareVersions() {
    dpkg --compare-versions "$1" "$2" "$3" >/dev/null
    return $?
}

function _mapPackage() {
    local pkg="$1"
    case "$pkg" in
        libraspberrypi-bin)
            isPlatform "osmc" && pkg="rbp-userland-osmc"
            isPlatform "xbian" && pkg="xbian-package-firmware"
            ;;
        libraspberrypi-dev)
            isPlatform "osmc" && pkg="rbp-userland-dev-osmc"
            isPlatform "xbian" && pkg="xbian-package-firmware"
            ;;
        mali-fbdev)
            isPlatform "vero4k" && pkg=""
            ;;
        # handle our custom package alias LINUX-HEADERS
        LINUX-HEADERS)
            if isPlatform "rpi"; then
                pkg="raspberrypi-kernel-headers"
            elif [[ -z "$__os_ubuntu_ver" ]]; then
                pkg="linux-headers-$(uname -r)"
            else
                pkg="linux-headers-generic"
            fi
            ;;
        # map libpng-dev to libpng12-dev for Jessie
        libpng-dev)
            compareVersions "$__os_debian_ver" lt 9 && pkg="libpng12-dev"
            ;;
        libsdl1.2-dev)
            rp_hasModule "sdl1" && pkg="RP sdl1 $pkg"
            ;;
        libsdl2-dev)
            if rp_hasModule "sdl2"; then
                # check whether to use our own sdl2 - can be disabled to resolve issues with
                # mixing custom 64bit sdl2 and os distributed i386 version on multiarch
                local own_sdl2=1
                # default to off for x11 targets due to issues with dependencies with recent
                # Ubuntu (19.04). eg libavdevice58 requiring exactly 2.0.9 sdl2.
                isPlatform "x11" && own_sdl2=0
                iniConfig " = " '"' "$configdir/all/retropie.cfg"
                iniGet "own_sdl2"
                if [[ "$ini_value" == "1" ]]; then
                    own_sdl2=1
                elif [[ "$ini_value" == "0" ]]; then
                    own_sdl2=0
                fi
                [[ "$own_sdl2" -eq 1 ]] && pkg="RP sdl2 $pkg"
            fi
            ;;
    esac
    echo "$pkg"
}