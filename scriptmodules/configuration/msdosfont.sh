#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="msdosfont"
rp_module_desc="Configure default console font size/type"
rp_module_section="config"
rp_module_flags="!x11"

function depends_msdosfont() {
    mkdir -p "/usr/share/fonts/truetype/msdos" >/dev/null
    cp "$rdscriptdir/fonts/*.ttf" "/usr/share/fonts/truetype/msdos/" >/dev/null
    fc-cache -f -v >/dev/null
}

function set_msdosfont() {
    iniConfig "=" '"' "/etc/default/console-setup"
    iniSet "FONTFACE" "$1"
    iniSet "FONTSIZE" "$2"
    service console-setup restart
    # force font configuration update if running from a pseudo-terminal
    [[ "$(tty | egrep '/dev/tty[1-6]')" == "" ]] && setupcon -f --force
}

function check_msdosfont() {
    local fontface
    local fontsize

    iniConfig "=" '"' "/etc/default/console-setup"
    iniGet "FONTFACE"
    fontface="$ini_value"
    iniGet "FONTSIZE"
    fontsize="$ini_value"
    echo "$fontface" "$fontsize"
}

function gui_msdosfont() {
    local cmd
    local options
    local choice

    cmd=(dialog --backtitle "$__backtitle" --menu "Choose the desired console font configuration: \n(Current configuration: $(check_consolefont))" 22 86 16)

    options=(
        1 "More Perfect DOS VGA (VGA 8x16)"
        2 "Less Perfect DOS VGA (VGA 8x16)"
        D "Default (Kernel font 8x16 - Restart needed)"
    )

    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

    if [[ -n "$choice" ]]; then
        case "$choice" in
            1)
                set_msdosfont "More Perfect DOS VGA" "8x16"
                ;;
            2)
                set_msdosfont "Less Perfect DOS VGA" "8x16"
                ;;
            D)
                set_msdosfont "" ""
                ;;
        esac
        if [[ "$choice" == "D" ]]; then
            printMsgs "dialog" "Default font will be used (provided by the Kernel).\n\nYou will need to reboot to see the change."
        else
            printMsgs "dialog" "New font configuration applied: $(check_consolefont)"
        fi
    fi
}
