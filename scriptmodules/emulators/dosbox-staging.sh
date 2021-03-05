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
#
# DosBox-staging
# Version for v0.77 onwards: geared towards meson build toolchain
# Note: Won't work with dosbox-staging v0.76 or earlier
# https://github.com/dosbox-staging/dosbox-staging/wiki/retropie-integration
#

rp_module_id="dosbox-staging"
rp_module_desc="DosBox-staging (enhanced and modern DosBox fork)"
rp_module_help="ROM Extensions: .bat .com .exe .sh .conf\n\nCopy your DOS games to $romdir/pc"
rp_module_licence="GPL2 https://github.com/dosbox-staging/dosbox-staging/blob/master/COPYING"
rp_module_section="emulators"

function depends_dosbox-staging() {
    getDepends ccache build-essential meson ninja-build libasound2-dev libpng-dev libsdl2-dev libsdl2-net-dev libopusfile-dev libfluidsynth-dev
}

function sources_dosbox-staging() {
    # gitPullOrClone "$md_build" https://github.com/dosbox-staging/dosbox-staging.git master
    # experimental for Pi4 only
    gitPullOrClone "$md_build" https://github.com/dosbox-staging/dosbox-staging.git kc/fps-pacing-1
}

function build_dosbox-staging() {
    # Fluidsynth (static)
    cd $md_build/contrib/static-fluidsynth
    make -j $(nproc)
    export PKG_CONFIG_PATH="${md_build}/contrib/static-fluidsynth/fluidsynth/build"
    export LD_LIBRARY_PATH="\$LD_LIBRARY_PATH:$md_inst"

    cd $md_build
    meson setup -Dbuildtype=release build
    ninja -C build

    md_ret_require=(
        "$md_build/build/dosbox"
        "$md_build/build/subprojects/munt-libmt32emu_2_4_2/libmt32emu.so"
    )
}

function install_dosbox-staging() {
    md_ret_files=(
        'build/dosbox'
        'build/subprojects/munt-libmt32emu_2_4_2/libmt32emu.so'
        'COPYING'
        'README'
    )
}

function configure_dosbox-staging() {
    local launcher_name="+Start DOSBox-staging.sh"
    local def="0"

    mkRomDir "pc"
    rm -f "$romdir/pc/$launcher_name"
    if [[ "$md_mode" == "install" ]]; then
        cat > "$romdir/pc/$launcher_name" << _EOF_
#!/bin/bash
#
# if present
#   /home/pi/.config/dosbox/dosbox-staging-git.conf
# will be used as primary config
#
params=("\$@")
if [[ -z "\${params[0]}" ]]; then
    params=(-c "@MOUNT C $romdir/pc -freesize 1024" -c "@C:")
elif [[ "\${params[0]}" == *.sh ]]; then
    bash "\${params[@]}"
    exit
elif [[ "\${params[0]}" == *.conf ]]; then
    params=(-userconf -conf "\${params[@]}")
else
    params+=(-exit)
fi

# MT-32 Munt library
export LD_LIBRARY_PATH="\$LD_LIBRARY_PATH:$md_inst"

"$md_inst/dosbox" "\${params[@]}"
_EOF_
        chmod +x "$romdir/pc/$launcher_name"
        chown $user:$user "$romdir/pc/$launcher_name"

        local config_path=$(su "$user" -c "\"$md_inst/dosbox\" -printconf")
        if [[ -f "$config_path" ]]; then
                iniConfig "=" "" "$config_path"
                iniSet "fullscreen" "true"
                iniSet "fullresolution" "desktop"
                iniSet "output" "texturenb"
                iniSet "texture_renderer" "opengles2"
                iniSet "cycles" "25000"
        fi
    fi

   addEmulator "$def" "$md_id" "pc" "bash $romdir/pc/${launcher_name// /\\ } %ROM%"
   addSystem "pc"
}