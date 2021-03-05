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
    echo "RetroDos version: $__version ($__version_commit)"
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
                dialog --yesno "Your user '$user' is not a member of the system group '$group'.\n\nThis is needed for RetroDos to function correctly. May I add '$user' to group '$group'?\n\nYou will need to restart for these changes to take effect." 22 76 2>&1 >/dev/tty && usermod -a -G "$group" "$user"
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
    chown -R $user:$user "$scriptdir"
    printHeading "Fetching latest version of the RetroDos script."
    pushd "$scriptdir" >/dev/null
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

function reboot_menu()
{
    cls
    reboot
}

function shutdown_menu()
{
    cls
    shutdown -h now
}

function config_gui_menu() {
    local default

    while true; do
        local options=()
        local idx

        for id in "${__mod_id[@]}"; do
            if [[ "${__mod_section[$id]}" == "config" ]] || rp_isInstalled "$id"; then
                options+=("${__mod_idx[$id]}" "${__mod_desc[$id]}" "${__mod_idx[$id]} ${__mod_desc[$id]}")
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
            *)
                local logfilename
                rps_logInit
                {
                    rps_logStart
                    id="${__mod_id[$choice]}"
                    if fnExists "gui_$id"; then
                        rp_callModule "$id" depends
                        rp_callModule "$id" gui
                    else
                        rp_callModule "$id" clean
                        rp_callModule "$id"
                    fi
                    rps_logEnd
                } &> >(_menu_gzip_log "$logfilename")
                rps_printInfo "$logfilename"
                ;;
        esac
    done
}

function emulators_gui_menu() {
    local default

    while true; do
        local options=()
        local idx

        for id in "${__mod_id[@]}"; do
            if [[ "${__mod_section[$id]}" == "emulators" ]] || rp_isInstalled "$id"; then
                options+=("${__mod_idx[$id]}" "${__mod_desc[$id]}" "${__mod_idx[$id]} ${__mod_desc[$id]}")
            fi
        done

        local cmd=(dialog --backtitle "$__backtitle" --title "Emulators" --cancel-label "Back" --item-help --help-button --default-item "$default" --menu "This menu contains configuration for emulators." 22 76 16)

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
            *)
                local logfilename
                rps_logInit
                {
                    rps_logStart
                    id="${__mod_id[$choice]}"
                    if fnExists "gui_$id"; then
                        rp_callModule "$id" depends
                        rp_callModule "$id" gui
                    else
                        rp_callModule "$id" clean
                        rp_callModule "$id"
                    fi
                    rps_logEnd
                } &> >(_menu_gzip_log "$logfilename")
                rps_printInfo "$logfilename"
                ;;
        esac
    done
}

# retrodos main menu
function gui_menu() {
    depends_menu
    local default

    while true; do
        local idx
        local commit=$(git -C "$scriptdir" log -1 --pretty=format:"%cr (%h)")
        local options=()

        for id in "${__mod_id[@]}"; do
            if [[ "${__mod_section[$id]}" == "games" ]] && fnExists "gui_$id"; then
                options+=("${__mod_idx[$id]}" "${__mod_desc[$id]}" "${__mod_idx[$id]} ${__mod_desc[$id]}")
            fi
        done

        options+=(C "Configuration / Tools" "C Configuration and tools.")
        options+=(E "Emulators" "E Emulators.")
        options+=(U "Update RetroDos script" "U Update RetroDos script. This will update this main management script only, but will not update any software packages. To update packages use the 'Update' option from the main menu, which will also update the RetroDos script.")
        options+=(R "Reboot" "R Reboot your machine.")
        options+=(X "Shutdown" "X Shutdown your machine.")

        cmd=(dialog --backtitle "$__backtitle" --title "$__title" --cancel-label "Exit" --item-help --help-button --default-item "$default" --menu "Version: $__version\nLast Commit: $commit\nSystem: $__platform ($__platform_arch) $__os_desc" 22 76 16)

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
            E)
                emulators_gui_menu
                ;;
            U)
                dialog --defaultno --yesno "Are you sure you want to update the RetroDos script?" 22 76 2>&1 >/dev/tty || continue
                if update_script_menu; then
                    exec "$scriptdir/retrodos_packages.sh" menu post_update gui_menu
                fi
                ;;
            R)
                dialog --defaultno --yesno "Are you sure you want to reboot?" 22 76 2>&1 >/dev/tty || continue
                reboot_menu
                ;;
            X)
                dialog --defaultno --yesno "Are you sure you want to shutdown?" 22 76 2>&1 >/dev/tty || continue
                shutdown_menu
                ;;
            *)
                local logfilename
                rps_logInit
                {
                    rps_logStart
                    id="${__mod_id[$choice]}"
                    if fnExists "gui_$id"; then
                        rp_callModule "$id" depends
                        rp_callModule "$id" gui
                    else
                        rp_callModule "$id" clean
                        rp_callModule "$id"
                    fi
                    rps_logEnd
                } &> >(_menu_gzip_log "$logfilename")
                rps_printInfo "$logfilename"
                ;;
        esac
    done
    cls
}
