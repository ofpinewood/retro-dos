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

rp_module_id="dosboxgames"
rp_module_desc="DOSBox Games"
rp_module_section="games"

dosboxgames_romdir="$romdir/pc/"
#dosboxgames_conf="$home/.config/dosbox/dosbox-staging-git.conf"

function depends_dosboxgames()
{
    dosboxgames_idx=()
    dosboxgames_conf=()
    dosboxgames_name=()
    dosboxgames_path=()

    local idx=0
    while IFS= read -d $'\0' -r path ; do
        local folder="${path##*/}"
        local conf="$path/dosbox.conf"
        local name="$folder"
        if [ -n "$name" ]; then
            dosboxgames_idx+=("$idx")
            dosboxgames_conf["$idx"]="$conf"
            dosboxgames_name["$idx"]="$name"
            dosboxgames_path["$idx"]="$path"
            ((idx++))
        fi
    done < <(find "$dosboxgames_romdir" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z)
}

function run_game_dosboxgames()
{
    local idx="$1"

    # ref: https://www.dosbox.com/DOSBoxManual.html
    # ref: https://retropie.org.uk/docs/PC/

    # MT-32 Munt library
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/retropie/emulators/dosbox-staging"

    local conf="${dosboxgames_conf[$idx]}"
    if [ -n "$conf" ]; then
        /opt/retropie/emulators/dosbox-staging/dosbox -userconf -conf "$conf" -exit
    else
        /opt/retropie/emulators/dosbox-staging/dosbox "${dosboxgames_path[$idx]}" -exit
    fi
}

function run_dosbox_dosboxgames()
{
    # ref: https://www.dosbox.com/DOSBoxManual.html
    # ref: https://retropie.org.uk/docs/PC/

    # MT-32 Munt library
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/retropie/emulators/dosbox-staging"

    /opt/retropie/emulators/dosbox-staging/dosbox "$dosboxgames_romdir" -c "c:"
}

function gui_dosboxgames() {
    while true; do
        local options=()

        options+=(D "DOSBox" "D DOSBox.")

        local idx
        for idx in "${dosboxgames_idx[@]}"; do
            options+=("${idx}" "${dosboxgames_name[$idx]}" "${idx} ${dosboxgames_name[$idx]}")
        done

        local cmd=(dialog --backtitle "$__backtitle" --title "DOSBox Games" --cancel-label "Back" --item-help --help-button --default-item "$default" --menu "Start a game" 22 76 16)

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

        if [[ -n "$choice" ]]; then
            case "$choice" in
                D)
                    run_dosbox_dosboxgames
                    ;;
                *)
                    run_game_dosboxgames "$choice"
                    ;;
            esac
        else
            break
        fi
    done
}
