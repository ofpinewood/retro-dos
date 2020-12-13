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

rp_module_id="scummvm-games"
rp_module_desc="ScummVM Games"
rp_module_section="main"

function gui_scummvm-games() {
    local gamelist="$configdir/all/emulationstation/gamelists/scummvm/gamelist.xml"
    local gamelist="$rdscriptdir/data/gamelist.xml"
    local text=$(<gamelist)

    local cmd=(dialog --backtitle "$__backtitle" --title "ScummVM Games" --cancel-label "Back" --item-help --help-button --default-item "$default" --menu "Start a game $text" 22 76 16)

    # while true; do
    #     local options=(
    #         atlantis "Indiana Jones and the Fate of Atlantis" "Indiana Jones and the Fate of Atlantis"

    #         monkey "The Secret of Monkey Island" "The Secret of Monkey Island"
    #     )

    #     local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    #     [[ -z "$choice" ]] && break
    #     if [[ "${choice[@]:0:4}" == "HELP" ]]; then
    #         choice="${choice[@]:5}"
    #         default="${choice/%\ */}"
    #         choice="${choice#* }"
    #         printMsgs "dialog" "$choice"
    #         continue
    #     fi

    #     [[ -z "$choice" ]] && break

    #     default="$choice"

    #     case "$choice" in
    #         # atlantis)
    #         #     printMsgs "dialog" "Indiana Jones and the Fate of Atlantis"
    #         #     ;;
    #         *)
    #             game="$choice"
    #             pushd "/home/pi/RetroPie/roms/scummvm" >/dev/null
    #             /opt/retropie/emulators/scummvm/bin/scummvm --fullscreen --joystick=0 --extrapath="/opt/retropie/emulators/scummvm/extra" $game
    #             while read id desc; do
    #                 echo "$desc" > "/home/pi/RetroPie/roms/scummvm/$id.svm"
    #             done < <(/opt/retropie/emulators/scummvm/bin/scummvm --list-targets | tail -n +3)
    #             popd >/dev/null
    #             ;;
    #     esac
    # done
}
