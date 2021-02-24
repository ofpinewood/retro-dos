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

__sections[games]="games"

function rp_registerModuleDir() {
    local dir="$1"
    local module
    for module in $(find "$scriptdir/scriptmodules/$dir" -maxdepth 1 -name "*.sh" | sort); do
        rp_registerModule "$module" "$dir"
    done
}

function rd_registerAllModules() {
    __mod_id=()
    declare -Ag __mod_idx=()
    declare -Ag __mod_type=()
    declare -Ag __mod_desc=()
    declare -Ag __mod_help=()
    declare -Ag __mod_licence=()
    declare -Ag __mod_section=()
    declare -Ag __mod_flags=()

    # rp_registerModuleDir "emulators"
    # rp_registerModuleDir "libretrocores"
    # rp_registerModuleDir "ports"

    rp_registerModuleDir "menu"
    rp_registerModuleDir "config"
    rp_registerModuleDir "games"

    # rp_registerModuleDir "supplementary"
    # rp_registerModuleDir "admin"
}

function rp_registerModule() {
    local path="$1"
    local type="$2"
    local rp_module_id=""
    local rp_module_desc=""
    local rp_module_help=""
    local rp_module_licence=""
    local rp_module_section=""
    local rp_module_flags=""

    local error=0

    source "$path"

    local var
    for var in rp_module_id rp_module_desc; do
        if [[ -z "${!var}" ]]; then
            echo "Module $module_path is missing valid $var"
            error=1
        fi
    done
    [[ $error -eq 1 ]] && exit 1

    local flags=($rp_module_flags)
    local flag
    local valid=1

    # flags are parsed in the order provided in the module - so the !all flag only makes sense first
    # by default modules are enabled for all platforms
    if [[ "$__ignore_flags" -ne 1 ]]; then
        for flag in "${flags[@]}"; do
            # !all excludes the module from all platforms
            if [[ "$flag" == "!all" ]]; then
                valid=0
                continue
            fi
            # flags without ! make the module valid for the platform
            if isPlatform "$flag"; then
                valid=1
                continue
            fi
            # flags with !flag will exclude the module for the platform
            if [[ "$flag" =~ ^\!(.+) ]] && isPlatform "${BASH_REMATCH[1]}"; then
                valid=0
                continue
            fi
        done
    fi

    local sections=($rp_module_section)
    # get default section
    rp_module_section="${sections[0]}"

    # loop through any additional flag=section parameters
    local flag section
    for section in "${sections[@]:1}"; do
        section=(${section/=/ })
        flag="${section[0]}"
        section="${section[1]}"
        isPlatform "$flag" && rp_module_section="$section"
    done

    if [[ "$valid" -eq 1 ]]; then
        # create numerical index for each module id from nunber of added modules
        __mod_idx["$rp_module_id"]="${#__mod_id[@]}"
        __mod_id+=("$rp_module_id")
        __mod_type["$rp_module_id"]="$type"
        __mod_desc["$rp_module_id"]="$rp_module_desc"
        __mod_help["$rp_module_id"]="$rp_module_help"
        __mod_licence["$rp_module_id"]="$rp_module_licence"
        __mod_section["$rp_module_id"]="$rp_module_section"
        __mod_flags["$rp_module_id"]="$rp_module_flags"
    fi
}

function rp_callModule() {
    local md_id="$1"
    local mode="$2"
    # shift the function parameters left so $@ will contain any additional parameters which we can use in modules
    shift 2

    # check for module
    if [[ -x "${__mod_idx[$md_id]}" ]]; then
        printMsgs "console" "No module '$md_id' found for platform $__platform"
        return 2
    fi

    # parameters _auto_ _binary or _source_ (_source_ is used if no parameters are given for a module)
    case "$mode" in
        # install the module if not installed, and update if it is
        _autoupdate_)
            if rp_isInstalled "$md_id"; then
                rp_callModule "$md_id" "_update_" || return 1
            else
                rp_callModule "$md_id" "_auto_" || return 1
            fi
            return 0
            ;;
        # automatic modes used by rp_installModule to choose between binary/source based on pkg info
        _auto_|_update_)
            # if updating and a package isn't installed, return an error
            if [[ "$mode" == "_update_" ]] && ! rp_isInstalled "$md_id"; then
                __ERRMSGS+=("$md_id is not installed, so can't update")
                return 1
            fi

            eval $(rp_getPackageInfo "$md_id")
            rp_hasBinary "$md_id"
            local ret="$?"

            # check if we had a network failure from wget
            if [[ "$ret" -eq 4 ]]; then
                __ERRMSGS+=("Unable to connect to the internet")
                return 1
            fi

            if [[ "$pkg_origin" != "source" ]] && [[ "$ret" -eq 0 ]]; then
                # if we are in _update_ mode we only update if there is a newer binary
                if [[ "$mode" == "_update_" ]]; then
                    rp_hasNewerBinary "$md_id"
                    local ret="$?"
                    [[ "$ret" -eq 1 ]] && return 0
                fi
                rp_callModule "$md_id" _binary_ || return 1
            else
                rp_callModule "$md_id" || return 1
            fi
            return 0
            ;;
        _binary_)
            for mode in depends install_bin configure; do
                rp_callModule "$md_id" "$mode" || return 1
            done
            return 0
            ;;
        # automatically build/install module from source if no _source_ or no parameters are given
        ""|_source_)
            for mode in depends sources build install configure clean; do
                rp_callModule "$md_id" "$mode" || return 1
            done
            return 0
            ;;
    esac

    # create variables that can be used in modules
    local md_desc="${__mod_desc[$md_id]}"
    local md_help="${__mod_help[$md_id]}"
    local md_type="${__mod_type[$md_id]}"
    local md_flags="${__mod_flags[$md_id]}"
    local md_build="$__builddir/$md_id"
    local md_inst="$(rp_getInstallPath $md_id)"
    local md_data="$scriptdir/scriptmodules/$md_type/$md_id"
    local md_mode="install"

    # set md_conf_root to $configdir and to $configdir/ports for ports
    # ports in libretrocores or systems (as ES sees them) in ports will need to change it manually with setConfigRoot
    local md_conf_root
    if [[ "$md_type" == "ports" ]]; then
        setConfigRoot "ports"
    else
        setConfigRoot ""
    fi

    case "$mode" in
        # remove sources
        clean)
            if [[ "$__persistent_repos" -eq 1 ]] && [[ -d "$md_build/.git" ]]; then
                git -C "$md_build" reset --hard
                git -C "$md_build" clean -f -d
            else
                rmDirExists "$md_build"
            fi
            return 0
            ;;
        # create binary archive
        create_bin)
            rp_createBin || return 1
            return 0
            ;;
        # echo module help to console
        help)
            printMsgs "console" "$md_desc\n\n$md_help"
            return 0;
            ;;
    esac

    # create function name
    function="${mode}_${md_id}"

    # automatically switch to install_bin if present while install is not, and handle cases where we have
    # fallback functions when not present in modules - currently install_bin and remove
    if ! fnExists "$function"; then
        if [[ "$mode" == "install" ]] && fnExists "install_bin_${md_id}"; then
            function="install_bin_${md_id}"
            mode="install_bin"
        elif [[ "$mode" != "install_bin" && "$mode" != "remove" ]]; then
            return 0
        fi
    fi

    # these can be returned by a module
    local md_ret_require=()
    local md_ret_files=()
    local md_ret_errors=()
    local md_ret_info=()

    local action
    local pushed=1
    case "$mode" in
        depends)
            if [[ "$1" == "remove" ]]; then
                md_mode="remove"
                action="Removing"
            else
                action="Installing"
            fi
            action+=" dependencies for"
            ;;
        sources)
            action="Getting sources for"
            mkdir -p "$md_build"
            pushd "$md_build"
            pushed=$?
            ;;
        build)
            action="Building"
            pushd "$md_build" 2>/dev/null
            pushed=$?
            ;;
        install)
            pushd "$md_build" 2>/dev/null
            pushed=$?
            ;;
        install_bin)
            action="Installing (binary)"
            ;;
        configure)
            action="Configuring"
            pushd "$md_inst" 2>/dev/null
            pushed=$?
            ;;
        remove)
            action="Removing"
            ;;
        _update_hook)
            ;;
        *)
            action="Running action '$mode' for"
            ;;
    esac

    # print an action and a description
    if [[ -n "$action" ]]; then
        printHeading "$action '$md_id' : $md_desc"
    fi

    case "$mode" in
        remove)
            fnExists "$function" && "$function" "$@"
            md_mode="remove"
            if fnExists "configure_${md_id}"; then
                pushd "$md_inst" 2>/dev/null
                pushed=$?
                "configure_${md_id}"
            fi
            rm -rf "$md_inst"
            printMsgs "console" "Removed directory $md_inst"
            ;;
        install)
            action="Installing"
            # remove any previous install folder unless noinstclean flag is set
            if ! hasFlag "${__mod_flags[$md_id]}" "noinstclean"; then
                rmDirExists "$md_inst"
            fi
            mkdir -p "$md_inst"
            "$function" "$@"
            ;;
        install_bin)
            if fnExists "install_bin_${md_id}"; then
                mkdir -p "$md_inst"
                if ! "$function" "$@"; then
                    md_ret_errors+=("Unable to install binary for $md_id")
                fi
            else
                if rp_hasBinary "$md_id"; then
                    rp_installBin
                else
                    md_ret_errors+=("Could not find a binary for $md_id")
                fi
            fi
            ;;
        *)
            # call the function with parameters
            "$function" "$@"
            ;;
    esac

    # check if any required files are found
    if [[ -n "$md_ret_require" ]]; then
        for file in "${md_ret_require[@]}"; do
            if [[ ! -e "$file" ]]; then
                md_ret_errors+=("Could not successfully $mode $md_id - $md_desc ($file not found).")
                break
            fi
        done
    fi

    if [[ "${#md_ret_errors}" -eq 0 && -n "$md_ret_files" ]]; then
        # check for existence and copy any files/directories returned
        local file
        for file in "${md_ret_files[@]}"; do
            if [[ ! -e "$md_build/$file" ]]; then
                md_ret_errors+=("Could not successfully install $md_desc ($md_build/$file not found).")
                break
            fi
            cp -Rvf "$md_build/$file" "$md_inst"
        done
    fi

    # remove build folder if empty
    [[ -d "$md_build" ]] && find "$md_build" -maxdepth 0 -empty -exec rmdir {} \;

    [[ "$pushed" -eq 0 ]] && popd

    # some errors were returned.
    if [[ "${#md_ret_errors[@]}" -gt 0 ]]; then
        __ERRMSGS+=("${md_ret_errors[@]}")
        printMsgs "console" "${md_ret_errors[@]}" >&2
        # if sources fails and we were called from the setup gui module clean sources
        if [[ "$mode" == "sources" && "$__setup" -eq 1 ]]; then
            rp_callModule "$md_id" clean
        fi
        # remove install folder if there is an error (and it is empty)
        [[ -d "$md_inst" ]] && find "$md_inst" -maxdepth 0 -empty -exec rmdir {} \;
        return 1
    else
        [[ "$mode" == "install_bin" ]] && rp_setPackageInfo "$md_id" "binary"
        [[ "$mode" == "install" ]] && rp_setPackageInfo "$md_id" "source"
        # handle the case of a few drivers that don't have an install function and set the package info at build stage
        if ! fnExists "install_${md_id}" && [[ "$mode" == "build" ]]; then
            rp_setPackageInfo "$md_id" "source"
        fi
    fi

    # some information messages were returned
    if [[ "${#md_ret_info[@]}" -gt 0 ]]; then
        __INFMSGS+=("${md_ret_info[@]}")
    fi

    return 0
}

function rp_getInstallPath() {
    local id="$1"
    echo "$rootdir/${__mod_type[$id]}/$id"
}

function rp_isInstalled() {
    local id="$1"
    local md_inst="$rootdir/${__mod_type[$id]}/$id"
    [[ -d "$md_inst" ]] && return 0
    return 1
}

function cls()
{
    # echo "clear"
    clear
}