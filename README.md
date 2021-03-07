# RetroDos <img src="msdos-logo-256x256.gif" alt="RetroDos" height="44" align="left" />

[![License: MIT](https://img.shields.io/github/license/ofpinewood/retro-dos.svg)](https://github.com/ofpinewood/retro-dos/blob/master/LICENSE)

RetroDos is a front-end for the RetroPie project. It's a bash script that displays menus.

![RetroDos screenshot](images/screenshot.png)

## General Usage
RetroDos is a shell script to start your ScummVM games and manage some configuration.

To run the RetroDos script make sure that your APT repositories are up-to-date and that Git is installed:

``` bash
sudo apt-get update
sudo apt-get dist-upgrade
sudo apt-get install git
```

You can then download the latest RetroDos script with:

``` bash
cd
git clone --depth=1 https://github.com/ofpinewood/retro-dos.git
```

The script is executed with:

``` bash
cd retro-dos
sudo ./retrodos.sh
```

> Note: When you first run the script it may install some additional packages that are needed.

## Development
All development will happen in its own feature branch, since the `main` branch is also the production version for the script.

``` bash
cd
git clone --depth=1 --single-branch --branch <feature> https://github.com/ofpinewood/retro-dos.git
```

References:
- [RetroPie](https://retropie.org.uk/)
- [Linux Shell Scripting Tutorial](https://bash.cyberciti.biz/guide)

### Windows development
Windows Subsystem for Linux is recommended to develop on Windows.

- [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

Make script files executable before checking them in.

``` cmd
git update-index --chmod=+x scriptmodules/<script>.sh;
```

## Configuration
Setup and configuration for my `Macintosh Classic II`-mod running RetroPie.

- [RetroPie setup](https://github.com/ofpinewood/retro-dos/docs/retropie-setup.md)
- [DOSBox](https://github.com/ofpinewood/retro-dos/docs/dosbox.md)
- [ScummVM](https://github.com/ofpinewood/retro-dos/docs/scummvm.md)

## Contributing
We accept fixes and features! Here are some resources to help you get started on how to contribute code or new content.

* [Contributing](https://github.com/ofpinewood/retro-dos/blob/master/CONTRIBUTING.md)
* [Code of conduct](https://github.com/ofpinewood/retro-dos/blob/master/CODE_OF_CONDUCT.md)

## Acknowledgments
- [RetroPie-Setup](https://github.com/RetroPie/RetroPie-Setup) for the bash script inspiration.

---
Copyright &copy; 2020, [Of Pine Wood](http://ofpinewood.com).
Created by [Peter van den Hout](http://ofpinewood.com).
Released under the terms of the [MIT license](https://github.com/ofpinewood/retro-dos/blob/master/LICENSE).
