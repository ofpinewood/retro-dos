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

rp_module_id="scummvmgames"
rp_module_desc="ScummVM Games"
rp_module_section="games"

scummvmgames_romdir="$romdir/scummvm/"
#scummvmgames_romdir="$scriptdir/data/roms/scummvm/"

function depends_scummvmgames()
{
    scummvmgames_idx=()
    scummvmgames_shortname=()
    scummvmgames_name=()
    scummvmgames_path=()

    local idx=0
    while IFS= read -d $'\0' -r path ; do
        local folder="${path##*/}"
        local shortname=$(<"$path/$folder.svm")
        if [ -n "$shortname" ]; then
            scummvmgames_idx+=("$idx")
            scummvmgames_shortname["$idx"]="$shortname"
            scummvmgames_name["$idx"]="$folder"
            scummvmgames_path["$idx"]="$path"
            ((idx++))
        fi
    done < <(find "$scummvmgames_romdir" -maxdepth 1 -mindepth 1 -type d -print0)
}

function run_game_scummvmgames()
{
    local shortname="$1"

    local name
    local path
    local idx
    for idx in "${scummvmgames_idx[@]}"; do
        if [[ "${scummvmgames_shortname[$idx]}" == $shortname ]]; then
            name="${scummvmgames_name[$idx]}"
            path="${scummvmgames_path[$idx]}"
        fi
    done

    # ref: https://docs.scummvm.org/en/latest/advanced_topics/command_line.html
    # ref: https://scumm-thedocs.readthedocs.io/en/latest/advanced/command_line.html
    /opt/retropie/emulators/scummvm/bin/scummvm --gfx-mode=1x --no-filtering --aspect-ratio --fullscreen --music-volume=96 --sfx-volume=144 --extrapath="/opt/retropie/emulators/scummvm/extra" --path="$path" $shortname
}

function gui_scummvmgames() {
    while true; do
        local options=()

        local idx
        for idx in "${scummvmgames_idx[@]}"; do
            options+=("${scummvmgames_shortname[$idx]}" "${scummvmgames_name[$idx]}" "${scummvmgames_shortname[$idx]} ${scummvmgames_name[$idx]}")
        done

        local cmd=(dialog --backtitle "$__backtitle" --title "ScummVM Games" --cancel-label "Back" --item-help --help-button --default-item "$default" --menu "Start a game" 22 76 16)

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
                    run_game_scummvmgames "$choice"
                    ;;
            esac
        else
            break
        fi
    done
}
