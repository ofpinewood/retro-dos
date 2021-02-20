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

# set config file
export DIALOGRC=./config.dialogrc

scriptdir="$(dirname "$0")"
scriptdir="$(cd "$scriptdir" && pwd)"

"$scriptdir/retrodos_packages.sh" menu gui
