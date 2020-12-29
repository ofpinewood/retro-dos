#!/bin/bash

# This file is part of RetroDos
#
# RetroDos front-end for RetroPie
# RetroDos is a front-end for the RetroPie project. It's a bash script to display menus.
#
# Author:         Peter van den Hout
# Website:        https://github.com/ofpinewood/retro-dos
# License:        MIT License (https://github.com/ofpinewood/retro-dos/master/LICENSE.md)
#

# Ref: https://github.com/RetroPie/RetroPie-Setup/blob/master/scriptmodules/admin/menu.sh

rp_module_id="menu"
rp_module_desc="RetroDos"
rp_module_section=""

function _menu_gzip_log() {
    setsid tee >(setsid gzip --stdout >"$1")
}

function rps_logInit() {
    if [[ ! -d "$__logdir" ]]; then
        if mkdir -p "$__logdir"; then
            chown $user:$user "$__logdir"
        else
            fatalError "Couldn't make directory $__logdir"
        fi
    fi
    local now=$(date +'%Y-%m-%d_%H%M%S')
    logfilename="$__logdir/rps_$now.log.gz"
    touch "$logfilename"
    chown $user:$user "$logfilename"
    time_start=$(date +"%s")
}

function rps_logStart() {
    echo -e "Log started at: $(date -d @$time_start)\n"
    echo "RetroPie-Setup version: $__version ($(git -C "$scriptdir" log -1 --pretty=format:%h))"
    echo "System: $__platform ($__platform_arch) - $__os_desc - $(uname -a)"
}

function rps_logEnd() {
    time_end=$(date +"%s")
    echo
    echo "Log ended at: $(date -d @$time_end)"
    date_total=$((time_end-time_start))
    local hours=$((date_total / 60 / 60 % 24))
    local mins=$((date_total / 60 % 60))
    local secs=$((date_total % 60))
    echo "Total running time: $hours hours, $mins mins, $secs secs"
}

function rps_printInfo() {
    reset
    if [[ ${#__ERRMSGS[@]} -gt 0 ]]; then
        printMsgs "dialog" "${__ERRMSGS[@]}"
        printMsgs "dialog" "Please see $1 for more in depth information regarding the errors."
    fi
    if [[ ${#__INFMSGS[@]} -gt 0 ]]; then
        printMsgs "dialog" "${__INFMSGS[@]}"
    fi
    __ERRMSGS=()
    __INFMSGS=()
}

function depends_menu() {
    # make sure user has the correct group permissions
    if ! isPlatform "x11"; then
        local group
        for group in input video; do
            if ! hasFlag "$(groups $user)" "$group"; then
                dialog --yesno "Your user '$user' is not a member of the system group '$group'.\n\nThis is needed for RetroPie to function correctly. May I add '$user' to group '$group'?\n\nYou will need to restart for these changes to take effect." 22 76 2>&1 >/dev/tty && usermod -a -G "$group" "$user"
            fi
        done
    fi

    # remove all but the last 20 logs
    find "$__logdir" -type f | sort | head -n -20 | xargs -d '\n' --no-run-if-empty rm

    # set a global __menu to 1 which is used to adjust package function behaviour if called from the menu gui
    __menu=1
}

function update_script_menu()
{
    cls
    chown -R $user:$user "$rdscriptdir"
    printHeading "Fetching latest version of the RetroDos script."
    pushd "$rdscriptdir" >/dev/null
    if [[ ! -d ".git" ]]; then
        printMsgs "dialog" "Cannot find directory '.git'. Please clone the RetroDos script via 'git clone https://github.com/ofpinewood/retro-dos.git'"
        popd >/dev/null
        return 1
    fi
    local error
    if ! error=$(su $user -c "git pull 2>&1 >/dev/null"); then
        printMsgs "dialog" "Update failed:\n\n$error"
        popd >/dev/null
        return 1
    fi
    popd >/dev/null

    printMsgs "dialog" "Fetched the latest version of the RetroDos script."
    return 0
}

function post_update_menu() {
    local return_func=("$@")

    echo "$__version" >"$rootdir/VERSION"

    cls
    local logfilename
    rps_logInit
    {
        rps_logStart
        # run _update_hook_id functions - eg to fix up modules for retropie-setup 4.x install detection
        printHeading "Running post update hooks"
        rp_updateHooks
        rps_logEnd
    } &> >(_menu_gzip_log "$logfilename")
    rps_printInfo "$logfilename"

    printMsgs "dialog" "NOTICE: The RetroDos script is available from https://github.com/ofpinewood/retro-dos."

    # return to set return function
    "${return_func[@]}"
}

function update_packages_menu() {
    cls
    local idx
    for idx in ${__mod_idx[@]}; do
        if rp_isInstalled "$idx" && [[ "${__mod_section[$idx]}" != "depends" ]]; then
            rp_installModule "$idx" "_update_" || return 1
        fi
    done
}

function update_packages_gui_menu() {
    local update="$1"
    if [[ "$update" != "update" ]]; then
        dialog --defaultno --yesno "Are you sure you want to update installed packages?" 22 76 2>&1 >/dev/tty || return 1
        update_script_menu || return 1
        # restart at post_update and then call "update_packages_gui_menu update" afterwards
        exec "$rdscriptdir/retrodos_packages.sh" menu post_update update_packages_gui_menu update
    fi

    local update_os=0
    dialog --yesno "Would you like to update the underlying OS packages (eg kernel etc) ?" 22 76 2>&1 >/dev/tty && update_os=1

    cls

    local logfilename
    rps_logInit
    {
        rps_logStart
        [[ "$update_os" -eq 1 ]] && rp_callModule raspbiantools apt_upgrade
        update_packages_menu
        rps_logEnd
    } &> >(_menu_gzip_log "$logfilename")
    rps_printInfo "$logfilename"

    printMsgs "dialog" "Installed packages have been updated."
    menu_gui_config
}

function reboot_menu()
{
    cls
    reboot
}

function config_gui_menu() {
    local default

    while true; do
        local options=(
            A "Update All" "A Updates RetroDos script and all currently installed packages. Will also allow to update OS packages. If binaries are available they will be used, otherwise packages will be built from source."

            U "Update RetroDos script"
            "U Update this RetroDos script. This will update this main management script only, but will not update any software packages."
        )

        local idx
        for idx in "${__mod_idx[@]}"; do
            # show all configuration modules and any installed packages with a gui function
            if [[ "${__mod_section[idx]}" == "config" ]] || rp_isInstalled "$idx" && fnExists "gui_${__mod_id[idx]}"; then
                options+=("$idx" "${__mod_desc[$idx]}" "$idx ${__mod_desc[$idx]} (${__mod_id[$idx]})")
            fi
        done

        local cmd=(dialog --backtitle "$__backtitle" --title "Configuration / Tools" --cancel-label "Back" --item-help --help-button --default-item "$default" --menu "This menu contains configuration and tools for RetroDos and from the RetroPie-Setup script." 22 76 16)

        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        [[ -z "$choice" ]] && break
        if [[ "${choice[@]:0:4}" == "HELP" ]]; then
            choice="${choice[@]:5}"
            default="${choice/%\ */}"
            choice="${choice#* }"
            printMsgs "dialog" "$choice"
            continue
        fi

        [[ -z "$choice" ]] && break

        default="$choice"

        case "$choice" in
            A)
                update_packages_gui_menu
                ;;
            U)
                dialog --defaultno --yesno "Are you sure you want to update the RetroDos script?" 22 76 2>&1 >/dev/tty || continue
                if update_script_menu; then
                    exec "$rdscriptdir/retrodos_packages.sh" menu post_update gui_menu
                fi
                ;;
            *)
                local logfilename
                rps_logInit
                {
                    rps_logStart
                    if fnExists "gui_${__mod_id[choice]}"; then
                        rp_callModule "$choice" depends
                        rp_callModule "$choice" gui
                    else
                        rp_callModule "$idx" clean
                        rp_callModule "$choice"
                    fi
                    rps_logEnd
                } &> >(_menu_gzip_log "$logfilename")
                rps_printInfo "$logfilename"
                ;;
        esac
    done
}

function package_menu() {
    local idx="$1"
    local md_id="${__mod_id[$idx]}"

    # associative array so we can pull out the messages later for the confirmation requester
    declare -A option_msgs=(
        ["U"]=""
        ["B"]="Install from pre-compiled binary"
        ["S"]="Install from source"
    )

    while true; do
        local options=()

        local status

        local has_binary=0
        rp_hasBinary "$idx"
        local binary_ret="$?"
        [[ "$binary_ret" -eq 0 ]] && has_binary=1

        local pkg_origin=""
        local source_update=0
        local binary_update=0
        if rp_isInstalled "$idx"; then
            eval $(rp_getPackageInfo "$idx")
            status="Installed - via $pkg_origin"
            [[ -n "$pkg_date" ]] && status+=" (built: $pkg_date)"

            if [[ "$pkg_origin" != "source" && "$has_binary" -eq 1 ]]; then
                rp_hasNewerBinary "$idx"
                local has_newer="$?"
                binary_update=1
                option_msgs["U"]="Update (from pre-built binary)"
                case "$has_newer" in
                    0)
                        status+="\nBinary update is available."
                        ;;
                    1)
                        status+="\nYou are running the latest binary."
                        option_msgs["U"]="Re-install (from pre-built binary)"
                        ;;
                    2)
                        status+="\nBinary update may be available (Unable to check for this package)."
                        ;;
                esac
            fi
            if [[ "$binary_update" -eq 0 && "$binary_ret" -ne 4 ]]; then
                source_update=1
                option_msgs["U"]="Update (from source)"
            fi
        else
            status="Not installed"
        fi

        # if we had a network error don't display install options
        if [[ "$binary_ret" -eq 4 ]]; then
            status+="\nInstall options disabled (Unable to access internet)"
        else
            if [[ "$source_update" -eq 1 || "$binary_update" -eq 1 ]]; then
                options+=(U "${option_msgs["U"]}")
            fi

            if [[ "$binary_update" -eq 0 && "$has_binary" -eq 1 ]]; then
                options+=(B "${option_msgs["B"]}")
            fi

            if [[ "$source_update" -eq 0 ]] && fnExists "sources_${md_id}"; then
                options+=(S "${option_msgs[S]}")
           fi
        fi

        if rp_isInstalled "$idx"; then
            if fnExists "gui_${md_id}"; then
                options+=(C "Configuration / Options")
            fi
            options+=(X "Remove")
        fi

        if [[ -d "$__builddir/$md_id" ]]; then
            options+=(Z "Clean source folder")
        fi

        local help="${__mod_desc[$idx]}\n\n${__mod_help[$idx]}"
        if [[ -n "$help" ]]; then
            options+=(H "Package Help")
        fi

        cmd=(dialog --backtitle "$__backtitle" --cancel-label "Back" --menu "Choose an option for ${__mod_id[$idx]}\n$status" 22 76 16)
        choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

        local logfilename

        case "$choice" in
            U|B|S)
                dialog --defaultno --yesno "Are you sure you want to ${option_msgs[$choice]}?" 22 76 2>&1 >/dev/tty || continue
                local mode
                case "$choice" in
                    U) mode="_auto_" ;;
                    B) mode="_binary_" ;;
                    S) mode="_source_" ;;
                esac
                clear
                rps_logInit
                {
                    rps_logStart
                    rp_installModule "$idx" "$mode"
                    rps_logEnd
                } &> >(_menu_gzip_log "$logfilename")
                rps_printInfo "$logfilename"
                ;;
            C)
                rps_logInit
                {
                    rps_logStart
                    rp_callModule "$idx" gui
                    rps_logEnd
                } &> >(_menu_gzip_log "$logfilename")
                rps_printInfo "$logfilename"
                ;;
            X)
                local text="Are you sure you want to remove $md_id?"
                case "${__mod_section[$idx]}" in
                    core)
                        text+="\n\nWARNING - core packages are needed for RetroPie to function!"
                        ;;
                    depends)
                        text+="\n\nWARNING - this package is required by other RetroPie packages - removing may cause other packages to fail."
                        text+="\n\nNOTE: This will be reinstalled if missing when updating packages that require it."
                        ;;
                esac
                dialog --defaultno --yesno "$text" 22 76 2>&1 >/dev/tty || continue
                rps_logInit
                {
                    rps_logStart
                    rp_callModule "$idx" remove
                    rps_logEnd
                } &> >(_menu_gzip_log "$logfilename")
                rps_printInfo "$logfilename"
                ;;
            H)
                printMsgs "dialog" "$help"
                ;;
            Z)
                rp_callModule "$idx" clean
                printMsgs "dialog" "$__builddir/$md_id has been removed."
                ;;
            *)
                break
                ;;
        esac

    done
}

function section_gui_menu() {
    local section="$1"

    local default=""
    while true; do
        local options=()
        local pkgs=()

        local idx
        local pkg_origin
        local num_pkgs=0
        for idx in $(rp_getSectionIds $section); do
            if rp_isInstalled "$idx"; then
                eval $(rp_getPackageInfo "$idx")
                installed="\Zb(Installed - via $pkg_origin)\Zn"
                ((num_pkgs++))
            else
                installed=""
            fi
            pkgs+=("$idx" "${__mod_id[$idx]} $installed" "$idx ${__mod_desc[$idx]}"$'\n\n'"${__mod_help[$idx]}")
        done

        if [[ "$num_pkgs" -gt 0 ]]; then
            options+=(
                U "Update all installed ${__sections[$section]} packages" "This will update any installed ${__sections[$section]} packages. The packages will be updated by the method used previously."
            )
        fi

        # allow installing an entire section except for drivers and dependencies - as it's probably a bad idea
        if [[ "$section" != "driver" && "$section" != "depends" ]]; then
            options+=(
                I "Install all ${__sections[$section]} packages" "This will install all ${__sections[$section]} packages. If a package is not installed, and a pre-compiled binary is available it will be used. If a package is already installed, it will be updated by the method used previously"
                X "Remove all ${__sections[$section]} packages" "X This will remove all $section packages."
            )
        fi

        options+=("${pkgs[@]}")

        local cmd=(dialog --colors --backtitle "$__backtitle" --cancel-label "Back" --item-help --help-button --default-item "$default" --menu "Choose an option" 22 76 16)

        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        [[ -z "$choice" ]] && break
        if [[ "${choice[@]:0:4}" == "HELP" ]]; then
            # remove HELP
            choice="${choice[@]:5}"
            # get id of menu item
            default="${choice/%\ */}"
            # remove id
            choice="${choice#* }"
            printMsgs "dialog" "$choice"
            continue
        fi

        default="$choice"

        local logfilename
        case "$choice" in
            U|I)
                local mode="update"
                [[ "$choice" == "I" ]] && mode="install"
                dialog --defaultno --yesno "Are you sure you want to $mode all $section packages?" 22 76 2>&1 >/dev/tty || continue
                rps_logInit
                {
                    rps_logStart
                    for idx in $(rp_getSectionIds $section); do
                        # if we are updating, skip packages that are not installed
                        if [[ "$mode" == "update" ]]; then
                            if rp_isInstalled "$idx"; then
                                rp_installModule "$idx" "_update_"
                            fi
                        else
                            rp_installModule "$idx" "_auto_"
                        fi
                    done
                    rps_logEnd
                } &> >(_menu_gzip_log "$logfilename")
                rps_printInfo "$logfilename"
                ;;
            X)
                local text="Are you sure you want to remove all $section packages?"
                [[ "$section" == "core" ]] && text+="\n\nWARNING - core packages are needed for RetroPie to function!"
                dialog --defaultno --yesno "$text" 22 76 2>&1 >/dev/tty || continue
                rps_logInit
                {
                    rps_logStart
                    for idx in $(rp_getSectionIds $section); do
                        rp_isInstalled "$idx" && rp_callModule "$idx" remove
                    done
                    rps_logEnd
                } &> >(_menu_gzip_log "$logfilename")
                rps_printInfo "$logfilename"
                ;;
            *)
                package_menu "$choice"
                ;;
        esac

    done
}

function packages_gui_menu() {
    local section
    local default
    local options=()

    for section in core main opt driver exp depends; do
        options+=($section "Manage ${__sections[$section]} packages" "$section Choose top install/update/configure packages from the ${__sections[$section]}")
    done

    local cmd
    while true; do
        cmd=(dialog --backtitle "$__backtitle" --cancel-label "Back" --item-help --help-button --default-item "$default" --menu "Choose an option" 22 76 16)

        local choice
        choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        [[ -z "$choice" ]] && break
        if [[ "${choice[@]:0:4}" == "HELP" ]]; then
            choice="${choice[@]:5}"
            default="${choice/%\ */}"
            choice="${choice#* }"
            printMsgs "dialog" "$choice"
            continue
        fi
        section_gui_menu "$choice"
        default="$choice"
    done
}

# retrodos main menu
function gui_menu() {
    depends_menu
    local default

    while true; do
        local idx
        local commit=$(git -C "$rdscriptdir" log -1 --pretty=format:"%cr (%h)")
        local options=()

        for idx in "${__mod_idx[@]}"; do
            if [[ "${__mod_section[idx]}" == "games" ]]; then
                options+=("$idx" "${__mod_desc[$idx]}" "$idx ${__mod_desc[$idx]} (${__mod_id[$idx]})")
            fi
        done

        options+=(C "Configuration / Tools" "C Configuration and tools.")
        options+=(P "Manage packages" "P Install/Remove and Configure the various components of RetroPie, including emulators, ports, and controller drivers.")
        options+=(R "Perform Reboot" "R Reboot your machine.")

        cmd=(dialog --backtitle "$__backtitle" --title "$__title" --cancel-label "Exit" --item-help --help-button --default-item "$default" --menu "Version: $__version - Last Commit: $commit\nSystem: $__platform ($__platform_arch) - running on $__os_desc" 22 76 16)

        choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        [[ -z "$choice" ]] && break

        if [[ "${choice[@]:0:4}" == "HELP" ]]; then
            choice="${choice[@]:5}"
            default="${choice/%\ */}"
            choice="${choice#* }"
            printMsgs "dialog" "$choice"
            continue
        fi
        default="$choice"

        case "$choice" in
            C)
                config_gui_menu
                ;;
            P)
                packages_gui_menu
                ;;
            R)
                dialog --defaultno --yesno "Are you sure you want to reboot?\n\nNote that if you reboot when Emulation Station is running, you will lose any metadata changes." 22 76 2>&1 >/dev/tty || continue
                reboot_menu
                ;;
            *)
                local logfilename
                rps_logInit
                {
                    rps_logStart
                    if fnExists "gui_${__mod_id[choice]}"; then
                        rp_callModule "$choice" depends
                        rp_callModule "$choice" gui
                    else
                        rp_callModule "$idx" clean
                        rp_callModule "$choice"
                    fi
                    rps_logEnd
                } &> >(_menu_gzip_log "$logfilename")
                rps_printInfo "$logfilename"
                ;;
        esac
    done
    cls
}