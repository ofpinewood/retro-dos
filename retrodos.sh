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

# set config file
export DIALOGRC=./config.dialogrc

rdscriptdir="$(dirname "$0")"
rdscriptdir="$(cd "$rdscriptdir" && pwd)"

"$rdscriptdir/retrodos_packages.sh" menu gui