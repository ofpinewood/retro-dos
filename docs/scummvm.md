# ScummVM

> The configuration is located under `root` since we are running `sudo retrodos.sh`.

## MT-32
ScummVM can emulate the MT-32 device, however you must provide the original MT-32 ROMs, taken from the MT-32 module, for the emulator to work. These files are:

- MT32_PCM.ROM
- MT32_CONTROL.ROM
- CM32L_PCM.ROM 
- CM32L_CONTROL.ROM

Place these ROMs in the game directory, in your extrapath (`/root/.config/scummvm/extra`), or in the directory where your ScummVM executable resides. ScummVM also looks for `CM32L_PCM.ROM` and `CM32L_CONTROL.ROM` — the ROMs from the CM-32L device — and uses these instead of the MT32 ROMs if they are available.