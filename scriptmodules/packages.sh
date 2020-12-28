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

# Ref: https://github.com/RetroPie/RetroPie-Setup/blob/master/scriptmodules/packages.sh

__configModules=" autostart splashscreen bootscreen consolefont skyscraper rdscraper "
__emulatorModules=" scummvm scummvm-sdl1 dosbox dosbox-sdl2 "
__gamesModules=" scummvm-games dosbox-games "

function rd_registerModuleDir() {
    local module_idx="$1"
    local module_dir="$2"
    for module in $(find "$rdscriptdir/scriptmodules/$2" -maxdepth 1 -name "*.sh" | sort); do
        rp_registerModule $module_idx "$module" "$module_dir"
        ((module_idx++))
    done
}

function rd_registerAllModules() {
    __mod_idx=()
    __mod_id=()
    __mod_type=()
    __mod_desc=()
    __mod_help=()
    __mod_licence=()
    __mod_section=()
    __mod_flags=()

    rp_registerModuleDir 100 "emulators"
    rp_registerModuleDir 200 "libretrocores"
    rp_registerModuleDir 300 "ports"
    rp_registerModuleDir 800 "supplementary"
    rp_registerModuleDir 900 "admin"
    rd_registerModuleDir 1000 "configuration"
    rd_registerModuleDir 1100 "menu"
}

function rd_isConfigModule() {
    local md_idx="$1"

    if [[ "$__configModules" == *" ${__mod_id[$md_idx]} "* ]]; then
        return 0
    fi
    return 1
}

function rd_isEmulatorModule() {
    local md_idx="$1"

    if [[ "$__emulatorModules" == *" ${__mod_id[$md_idx]} "* ]]; then
        return 0
    fi
    return 1
}

function rd_isGamesModule() {
    local md_idx="$1"

    if [[ "$__gamesModules" == *" ${__mod_id[$md_idx]} "* ]]; then
        return 0
    fi
    return 1
}

function cls()
{
    echo "clear"
    #clear
}