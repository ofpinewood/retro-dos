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

rp_module_id="bootscreen"
rp_module_desc="Configure the RetroDos splashscreen."
rp_module_section="config"
#rp_module_flags="noinstclean !all rpi !osmc !xbian !aarch64"

function depends_bootscreen() {
    local params=(insserv)
    isPlatform "32bit" && params+=(omxplayer)
    getDepends "${params[@]}"
}

function default_bootscreen() {
    echo "$rdscriptdir/splashscreens/msdos-1024x768-loading.png" >/etc/splashscreen.list
}

function set_bootscreen() {
    local mode="$1"
    local path
    local file
    while true; do
        path="$(choose_path_bootscreen)"
        [[ -z "$path" ]] && break
        file=$(choose_splashscreen "$path")
        if [[ -n "$file" ]]; then
            echo "$file" >/etc/splashscreen.list
            printMsgs "dialog" "Splashscreen set to '$file'"
            break
        fi
    done
}

function preview_bootscreen() {
    local path="$(choose_path_bootscreen)"
    local file
    local omxiv="/opt/retropie/supplementary/omxiv/omxiv"

    [[ -z "$path" ]] && break

    while true; do
        file=$(choose_splashscreen "$path" "image")
        [[ -z "$file" ]] && break
        $omxiv -b "$file"
    done
}

function choose_path_bootscreen() {
    local options=(
        1 "RetroDos splashscreens" "RetroDos splashscreens"
        2 "RetroPie splashscreens" "RetroPie splashscreens"
        3 "Custom splashscreens" "Own/Extra splashscreens (from $datadir/splashscreens)"
    )

    local cmd=(dialog --backtitle "$__backtitle" --title "Preview splashscreens" --cancel-label "Back" --item-help --menu "Choose an option." 22 86 16)

    local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    [[ "$choice" -eq 1 ]] && echo "$rdscriptdir/splashscreens"
    [[ "$choice" -eq 2 ]] && echo "$md_inst"
    [[ "$choice" -eq 3 ]] && echo "$datadir/splashscreens"
}

function gui_bootscreen() {
    echo "md_inst $md_inst"
    if [[ ! -d "$md_inst" ]]; then
        rp_callModule bootscreen depends
        rp_callModule bootscreen install
    fi

    while true; do
        local options=()
        options+=(D "Use default splashscreen" "Use default splashscreen")
        options+=(P "Preview splashscreens" "Preview splashscreens")
        options+=(C "Choose splashscreen" "Choose splashscreen")

        local cmd=(dialog --backtitle "$__backtitle" --title "Configure the RetroDos splashscreen" --cancel-label "Back" --item-help --help-button --default-item "$default" --menu "Configure the RetroDos splashscreen, to configure more splashscreen options use the splashscreen module (839)." 22 76 16)

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
                    default_bootscreen
                    printMsgs "dialog" "Splashscreen set to RetroDos default."
                    ;;
                P)
                    preview_bootscreen
                    ;;
                C)
                    set_bootscreen
                    ;;
            esac
        else
            break
        fi
    done
}