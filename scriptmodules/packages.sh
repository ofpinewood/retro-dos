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

__sections[games]="games"

function rd_registerModuleDir() {
    local dir="$1"
    local module
    for module in $(find "$rdscriptdir/scriptmodules/$dir" -maxdepth 1 -name "*.sh" | sort); do
        rp_registerModule "$module" "$dir"
    done
}

function rd_registerAllModules() {
    __mod_id=()
    declare -Ag __mod_idx=()
    declare -Ag __mod_type=()
    declare -Ag __mod_desc=()
    declare -Ag __mod_help=()
    declare -Ag __mod_licence=()
    declare -Ag __mod_section=()
    declare -Ag __mod_flags=()

    rp_registerModuleDir "emulators"
    rp_registerModuleDir "libretrocores"
    rp_registerModuleDir "ports"

    rd_registerModuleDir "menu"
    rd_registerModuleDir "config"
    rd_registerModuleDir "games"

    rp_registerModuleDir "supplementary"
    rp_registerModuleDir "admin"
}

function cls()
{
    # echo "clear"
    clear
}