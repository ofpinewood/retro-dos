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

function post_update_menu() {
    local return_func=("$@")

    echo "$__version" >"$rootdir/VERSION"

    cls
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
        exec "$scriptdir/retrodos_packages.sh" menu post_update update_packages_gui_menu update
    fi

    local update_os=0
    dialog --yesno "Would you like to update the underlying OS packages (eg kernel etc) ?" 22 76 2>&1 >/dev/tty && update_os=1

    cls
    printMsgs "dialog" "Installed packages have been updated."
    menu_gui_config
}

function reboot_menu()
{
    cls
    reboot
}

function menu_gui_games() {
    local module="games"
    rp_callModule "$module" depends
    rp_callModule "$module" gui
}

function menu_gui_config() {
    local default

    while true; do
        local idx
        local options=(
            A "Update All" "A Updates RetroDos script and all currently installed packages. Will also allow to update OS packages. If binaries are available they will be used, otherwise packages will be built from source."

            U "Update RetroDos script"
            "U Update this RetroDos script. This will update this main management script only, but will not update any software packages."
        )

        for idx in "${__mod_idx[@]}"; do
            if rd_isConfigModule "$idx"; then
                options+=("$idx" "${__mod_id[$idx]}" "$idx ${__mod_desc[$idx]}")
            fi
        done

        for idx in "${__mod_idx[@]}"; do
            if rd_isEmulatorModule "$idx"; then
                options+=("$idx" "${__mod_id[$idx]}" "$idx ${__mod_desc[$idx]}")
            fi
        done

        local cmd=(dialog --backtitle "$__backtitle" --title "Configuration / Tools" --cancel-label "Back" --item-help --help-button --default-item "$default" --menu "This menu contains configuration and tools for RetroDos. You can find more configuration options in the RetroPie-Setup script." 22 76 16)

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
                    exec "$scriptdir/retrodos_packages.sh" menu post_update gui_menu
                fi
                ;;
            *)
                if fnExists "gui_${__mod_id[choice]}"; then
                    rp_callModule "$choice" depends
                    rp_callModule "$choice" gui
                else
                    rp_callModule "$idx" clean
                    rp_callModule "$choice"
                fi
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
        local commit=$(git -C "$rdscriptdir" log -1 --pretty=format:"%cr (%h)")
        local options=()

        for idx in "${__mod_idx[@]}"; do
            if rd_isGamesModule "$idx"; then
                options+=("$idx" "${__mod_id[$idx]}" "$idx ${__mod_desc[$idx]}")
            fi
        done

        options+=(C "Configuration / Tools" "C Configuration and tools.")
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
                menu_gui_config
                ;;
            R)
                dialog --defaultno --yesno "Are you sure you want to reboot?\n\nNote that if you reboot when Emulation Station is running, you will lose any metadata changes." 22 76 2>&1 >/dev/tty || continue
                reboot_menu
                ;;
            *)
                if fnExists "gui_${__mod_id[choice]}"; then
                    rp_callModule "$choice" depends
                    rp_callModule "$choice" gui
                else
                    rp_callModule "$idx" clean
                    rp_callModule "$choice"
                fi
                ;;
        esac
    done
    cls
}