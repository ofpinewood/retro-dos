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
The default config file is located under `~/.config/dosbox/`. It should be named after either `dosbox-staging.conf` or `dosbox-staging-git.conf`.

To run a game (or a program) with a specific config, simply type in the following command:

``` cmd
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
