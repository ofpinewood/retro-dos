# RetroDos <img src="msdos-logo-256x256.gif" alt="RetroDos" height="44" align="left" />

[![License: MIT](https://img.shields.io/github/license/ofpinewood/retro-dos.svg)](https://github.com/ofpinewood/retro-dos/blob/master/LICENSE)

RetroDos is a front-end for the RetroPie project. It's a shell script to display menus, made to resemble a MS-DOS menu.

## Preview
# TODO: add previews

## Details
- System, basic, detailed, grid, video and menu views are supported.
- Support for new "All Games", "Favorites", "Last Played" and "Custom Collections" features in latest version of EmulationStation.
- Displays rating, description, # of players, genre, publish date & last played metadata on detailed and video views

## General Usage
Shell script to manage your RetroPie installation, using this RetroDos script as the 'graphical' front end.

To run the RetroDos script make sure that your APT repositories are up-to-date and that Git is installed:

``` bash
sudo apt-get update
sudo apt-get dist-upgrade
sudo apt-get install git
```

Then you can download the latest RetroPie setup script with:

``` bash
cd
git clone --depth=1 https://github.com/ofpinewood/retro-dos.git
```

The script is executed with:

``` bash
cd retro-dos
sudo ./retrodos.sh
```

When you first run the script it may install some additional packages that are needed.

## Development

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

## Contributing
We accept fixes and features! Here are some resources to help you get started on how to contribute code or new content.

* [Contributing](https://github.com/ofpinewood/retro-dos/blob/master/CONTRIBUTING.md)
* [Code of conduct](https://github.com/ofpinewood/retro-dos/blob/master/CODE_OF_CONDUCT.md)

## Acknowledgments
- [RetroPie-Setup](https://github.com/RetroPie/RetroPie-Setup) for the bash script inspiration.
- [More Perfect DOS VGA](http://laemeur.sdf.org/fonts) font by [Adam Moore (LÆMEUR)](http://laemeur.sdf.org/).

---
Copyright &copy; 2020, [Of Pine Wood](http://ofpinewood.com).
Created by [Peter van den Hout](http://ofpinewood.com).
Released under the terms of the [MIT license](https://github.com/ofpinewood/retro-dos/blob/master/LICENSE).
