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

# main retropie install location
rootdir="/opt/retropie"

# if __user is set, try and install for that user, else use SUDO_USER
if [[ -n "$__user" ]]; then
    user="$__user"
    if ! id -u "$__user" &>/dev/null; then
        echo "User $__user not exist"
        exit 1
    fi
else
    user="$SUDO_USER"
    [[ -z "$user" ]] && user="$(id -un)"
fi

home="$(eval echo ~$user)"
datadir="$home/RetroPie"
biosdir="$datadir/BIOS"
romdir="$datadir/roms"
emudir="$rootdir/emulators"
configdir="$rootdir/configs"

# TODO: check that RetroPie-Setup is installed here
scriptdir="$home/RetroPie-Setup" #/home/wsl2/RetroPie-Setup
scriptdir="$(cd "$scriptdir" && pwd)"

rdscriptdir="$(dirname "$0")"
rdscriptdir="$(cd "$rdscriptdir" && pwd)"

__logdir="$rdscriptdir/logs"
__tmpdir="$scriptdir/tmp"
__builddir="$__tmpdir/build"
__swapdir="$__tmpdir"

# check, if sudo is used
if [[ "$(id -u)" -ne 0 ]]; then
    echo "Script must be run under sudo from the user you want to install for. Try 'sudo $0'"
    exit 1
fi

__title="RetroDos"
__version="0.0.1-alpha"
__versionYear="2020"
__author="Of Pine Wood"
__backtitle="$__title (c) $__versionYear $__author $__version"

# using the RetroPie-Setup scriptmodules
source "$scriptdir/scriptmodules/system.sh"
source "$scriptdir/scriptmodules/helpers.sh"
source "$scriptdir/scriptmodules/inifuncs.sh"
source "$scriptdir/scriptmodules/packages.sh"
source "$rdscriptdir/scriptmodules/packages.sh"

setup_env

rd_registerAllModules

rp_ret=0
if [[ $# -gt 0 ]]; then
    setupDirectories
    rp_callModule "$@"
    rp_ret=$?
else
    rp_printUsageinfo
fi

if [[ "${#__ERRMSGS[@]}" -gt 0 ]]; then
    # override return code if ERRMSGS is set - eg in the case of calling basic_install from setup
    # we won't get the return code, as we don't handle return codes when calling non packaging functions
    # as it would require all modules functions to handle errors differently, and make things more complicated
    [[ "$rp_ret" -eq 0 ]] && rp_ret=1
    printMsgs "console" "Errors:\n${__ERRMSGS[@]}"
fi

if [[ "${#__INFMSGS[@]}" -gt 0 ]]; then
    printMsgs "console" "Info:\n${__INFMSGS[@]}"
fi

exit $rp_ret