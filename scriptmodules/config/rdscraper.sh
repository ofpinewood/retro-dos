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

rp_module_id="rdscraper"
rp_module_desc="Scrape games using SkyScraper."
rp_module_section="config"

function scrape_scummvm_scraper()
{
    local system="scummvm"
    local flags="unattend,skipped,video,relative"
    local scrape_source=""

    cls
    pushd "$rootdir/supplementary/skyscraper" >/dev/null
    # trap ctrl+c and return if pressed (rather than exiting retropie-setup etc)
    # trap 'trap 2; return 1' INT
    #     sudo -u "$user" stdbuf -o0 "$rootdir/supplementary/skyscraper/Skyscraper" -p "$system" -s "screenscraper" -g "$romdir/$system" -o "$romdir/$system/media" --flags "$flags" --refresh
    #     echo -e "\nCOMMAND LINE USED:\n $user $rootdir/supplementary/skyscraper/Skyscraper -p $system -s screenscraper -g $romdir/$system -o $romdir/$system/media --flags $flags --refresh"
    #     sleep 2
    # trap 2

    #"$rootdir/supplementary/skyscraper/Skyscraper" -p "$system" -s "screenscraper" -g "$romdir/$system" -o "$romdir/$system/media" --flags "$flags" --refresh
    #./Skyscraper -p "$system" -s "thegamesdb" -g "$romdir/$system" -o "$romdir/$system/media" --flags "$flags" --refresh
    #./Skyscraper -p "$system" -s "mobygames" -g "$romdir/$system" -o "$romdir/$system/media" --flags "$flags" --refresh
    popd >/dev/null
}

function scrape_dosbox_scraper()
{
    cls
}

function gui_scraper() {
    local cmd=(dialog --backtitle "$__backtitle" --title "Scraper" --cancel-label "Back" --item-help --help-button --default-item "$default" --menu "Choose an option" 22 76 16)
    local options=(
        S "Scrape ScummVM Games"
        "S Scrape the ScummVM games using SkyScraper."

        # D "Scrape Dosbox Games"
        # "D Scrape the Dosbox games using SkyScraper."
    )

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
        S)
            dialog --defaultno --yesno "Are you sure you want to (re)scrape the ScummVM games?" 22 76 2>&1 >/dev/tty || continue
            scrape_scummvm_scraper
            ;;
        D)
            dialog --defaultno --yesno "Are you sure you want to (re)scrape the Dosbox games?" 22 76 2>&1 >/dev/tty || continue
            scrape_dosbox_scraper
            ;;
    esac
}