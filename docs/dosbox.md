# DosBox-Staging
DOSBox Staging is an attempt to revitalize DOSBox's development process. In our case we are using the `kc/fps-pacing-1` branch for the Pi4.

- [Pi4 "kc/fps-pacing-1" branch](https://github.com/dosbox-staging/dosbox-staging/tree/kc/fps-pacing-1)
- [DOSBox official thread](https://retropie.org.uk/forum/topic/25041/dosbox-official-thread)
- [Games issues](https://github.com/dosbox-staging/dosbox-staging/wiki/Games-issues)
- [Compatibility](https://www.dosbox.com/comp_list.php)

## Retropie Integration
From within the GUI navigate to `Emulators`. There you should see a `dosbox-staging` entry. Go for it and choose to `Install/Update from Source`. Compilation should go smooth (~7-8min on a Pi4) and you'll have latest Fluidsynth and Munt libraries built as well.

> [Retropie Integration](https://github.com/dosbox-staging/dosbox-staging/wiki/retropie-integration)

## Configuration
The default config file is located under `root/.config/dosbox/`. It should be named after either `dosbox-staging.conf` or `dosbox-staging-git.conf`.

> The configuration is located under `root` since we are running `sudo retrodos.sh`.

```txt
[sdl]
fullscreen       = true
fullresolution   = desktop
output           = texturenb
texture_renderer = opengles2

[cpu]
cycles    = fixed 25000
```

To run a game (or a program) with a specific config, simply type in the following command:

``` bash
$ ./dosbox-staging -userconf -conf <path|name>.conf
```

> [Config file examples](https://github.com/dosbox-staging/dosbox-staging/wiki/Config-file-examples)

## Turn on dispmanx
One option to fix tearing is to turn on `dispmanx` in RetroPie setup. It does fix tearing yet it decreases performance in few games (eg. Alone in the Dark, Wolf3D, Crusader, etc).

```
RetroPie-Setup -> Configuration / Tools -> dispmanx // switch it on for DOSBOX
```

## Sound
> [Sound (wiki)](https://www.dosbox.com/wiki/Sound)

### MIDI
Configure your game to use General MIDI (GM) output on port `330`.

If you did not get the SoundFont by installing DosBox-Staging/FluidSynth, use the following commands. This will install the `.sf2` files in the `/usr/share/sounds/sf2/` folder.

``` bash
# General MIDI SoundFont
sudo apt-get install fluid-soundfont-gm

# Roland GS-compatible SoundFont
sudo apt-get install fluid-soundfont-gs
```

> The General MIDI SoundFont file is about 140MBytes and the GS-compatible SoundFont file is about 32MBytes in size.

After installing the soundfonts update the `root/.config/dosbox/dosbox-staging-git.conf` to point to one of the sound fonts.

``` txt
[fluidsynth]
soundfont = /usr/share/sounds/sf2/FluidR3_GM.sf2
```

### MT32
The the `/root/.config/dosbox/mt32-roms` directory in your DOSBox configuration must contain one or both pairs of MT-32 and/or CM-32L ROMs.
The files must be named in capitals, as follows:
- MT-32 ROM pair: MT32_CONTROL.ROM and MT32_PCM.ROM
- CM-32L ROM pair: CM32L_CONTROL.ROM and CM32L_PCM.ROM

The default (auto) prefers CM-32L if both sets of ROMs are provided. For early Sierra games and Dune 2 it's recommended 
to use `mt32`, while newer games typically made use of the CM-32L's extra sound effects (use `auto` or `cm32l`)

``` txt
[mt32]
model = auto
```

## Remarks
- I also use `vgaonly` (early 90s VGA games) or `vesa_nolfb` (mid-90s or higher resolution games), unless a game specifically needs something else.

- Another thing I do is disable all the sound devices and only enable those used by the game. Most SB-based games work well with `sbpro2` instead of `sb16` (unless you notice their configuration program specifically wanting a High DMA or HDMA - then you know the game uses 16-bit samples). I tend to use a sampling rates of 16000 for PC Speaker games, 22050 for older games, and 44100 for newer or CDDA games or 48000 for CDDA games w/ Opus files. That's all pretty minor though.