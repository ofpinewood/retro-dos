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
rp_module_desc="DosBox Games"
rp_module_section="games"

dosboxgames_romdir="$romdir/pc/"

[[ ! -n "$(aconnect -o | grep -e TiMidity -e FluidSynth)" ]] && needs_synth="1"

function depends_dosboxgames()
{
    dosboxgames_idx=()
    dosboxgames_conf=()
    dosboxgames_name=()
    dosboxgames_cmd=()
    dosboxgames_path=()

    local idx=0
    while IFS= read -d $'\0' -r path ; do
        local folder="${path##*/}"
        local conf="$path/dosbox.conf"
        local name=$(<"$path/dosbox.name")
        local cmd=$(<"$path/dosbox.cmd")
        if [ -n "$name" ]; then
            dosboxgames_idx+=("$idx")
            dosboxgames_conf["$idx"]="$conf"
            dosboxgames_name["$idx"]="$name"
            dosboxgames_cmd["$idx"]="$cmd"
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
    # fullscreen stuff: https://retropie.org.uk/forum/topic/25178/dosbox-on-pi-4-game-window-is-fullscreen-but-not-centered-on-screen/97?_=1614883985849&lang=en-US
    # Compatibility: https://www.dosbox.com/comp_list.php
    midi_synth start
    XINIT:bash /opt/retropie/emulators/dosbox/bin/dosbox -userconf -conf "${dosboxgames_conf[$idx]}" -c "mount c ${dosboxgames_path[$idx]}" -c "c:" -c "${dosboxgames_cmd[$idx]}" -c "exit"
    midi_synth stop
}

function midi_synth() {
    [[ "$needs_synth" != "1" ]] && return

    case "$1" in
        "start")
            timidity -Os -iAD &
            i=0
            until [[ -n "$(aconnect -o | grep TiMidity)" || "$i" -ge 10 ]]; do
                sleep 1
                ((i++))
            done
            ;;
        "stop")
            killall timidity
            ;;
        *)
            ;;
    esac
}


function gui_dosboxgames() {
    while true; do
        local options=()

        local idx
        for idx in "${dosboxgames_idx[@]}"; do
            options+=("${idx}" "${dosboxgames_name[$idx]}" "${idx} ${dosboxgames_name[$idx]}")
        done

        local cmd=(dialog --backtitle "$__backtitle" --title "DosBox Games" --cancel-label "Back" --item-help --help-button --default-item "$default" --menu "Start a game" 22 76 16)

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
                *)
                    run_game_dosboxgames "$choice"
                    ;;
            esac
        else
            break
        fi
    done
}
