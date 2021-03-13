# ScummVM

> The configuration is located under `root` since we are running `sudo retrodos.sh`.

## MT-32
ScummVM can emulate the MT-32 device, however you must provide the original MT-32 ROMs, taken from the MT-32 module, for the emulator to work. These files are:

- MT32_PCM.ROM
- MT32_CONTROL.ROM
- CM32L_PCM.ROM 
- CM32L_CONTROL.ROM

Place these ROMs in the game directory, in your extrapath (`/root/.config/scummvm/extra`), or in the directory where your ScummVM executable resides. ScummVM also looks for `CM32L_PCM.ROM` and `CM32L_CONTROL.ROM` — the ROMs from the CM-32L device — and uses these instead of the MT32 ROMs if they are available.

## Settings (.INI)
The `.ini` file can be found in: `/root/.config/scummvm`.

```ini
[scummvm]
filtering=false
midi_gain=100
mute=false
speech_volume=192
native_mt32=false
mt32_device=mt32
aspect_ratio=true
talkspeed=60
gui_use_game_language=false
extrapath=/root/.config/scummvm/extra
subtitles=false
multi_midi=true
fullscreen=true
gui_browser_show_hidden=false
browser_lastpath=/usr/share/sounds/sf2
gm_device=fluidsynth
soundfont=/usr/share/sounds/sf2/FluidR3_GM.sf2
sfx_volume=168
music_volume=192
autosave_period=300
music_driver=auto
opl_driver=auto
local_server_port=12345
versioninfo=2.2.0
speech_mute=false
enable_gs=false
```
