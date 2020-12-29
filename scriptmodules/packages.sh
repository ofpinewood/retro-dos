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

__config_modules=" bootscreen msdosfont rdscraper "
__rpconfig_modules=" autostart splashscreen consolefont skyscraper "
__emulator_modules=" scummvm scummvm-sdl1 dosbox dosbox-sdl2 "
__games_modules=" scummvmgames dosboxgames "

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

    if [[ "$__config_modules" == *" ${__mod_id[$md_idx]} "* ]]; then
        return 0
    fi
    return 1
}

function rd_isRpConfigModule() {
    local md_idx="$1"

    if [[ "$__rpconfig_modules" == *" ${__mod_id[$md_idx]} "* ]]; then
        return 0
    fi
    return 1
}

function rd_isEmulatorModule() {
    local md_idx="$1"

    if [[ "$__emulator_modules" == *" ${__mod_id[$md_idx]} "* ]]; then
        return 0
    fi
    return 1
}

function rd_isGamesModule() {
    local md_idx="$1"

    if [[ "$__games_modules" == *" ${__mod_id[$md_idx]} "* ]]; then
        return 0
    fi
    return 1
}

function cls()
{
    echo "clear"
    #clear
}