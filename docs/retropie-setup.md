# RetroPie setup
These settings are for my `Macintosh Classic II` running RetroPie.

## Setup WIFI

## Enable SFTP

### Enable Root access

## Boot into shell

## Overscan
Overscan settings are set in the `/boot/config.txt`. Make sure the top+bottom and left+right are a multiple of 8 to avoid scaling issues (blurred text and images).

``` txt
# disable the default values of overscan that is set by the firmware
disable_overscan=1

# overscan settings to account for the case overlap of the 10" LCD.
overscan_left=14
overscan_right=18
overscan_top=12
overscan_bottom=20
```

> NOTE: set the `disable_overscan=1` setting to disable the default values of overscan that is set by the firmware.

> Refrences:
> - [Video options in config.txt](https://www.raspberrypi.org/documentation/configuration/config-txt/video.md)