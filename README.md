The Gentoo Pi SD card maker
===========================

Warning: This in a very early stage of development. THe code works but you can
not rely on it. I will add reliability next...

This script is partitioning, formating partitions, downloads a Raspbian Linux
Kernel, downloads Gentoo image and installs it, downloads a portage package
tree and finalizes theinstallation to boot a Gentoo based GNU/Linux operating
system on a Raspberry Pi device.

Just insert the SD card after creation into your Raspberry Pi and
it will boot a Gentoo OS with a serial TTY enabled and SSH running. Sure, the
is some stuff to do but actually it works pretty well.

This project based on the following documentation:

 * https://wiki.gentoo.org/wiki/Raspberry_Pi
 * https://wiki.gentoo.org/wiki/Raspberry_Pi/Quick_Install_Guide
 * http://elinux.org/RPi_Advanced_Setup
 * http://elinux.org/RPi_SD_cards
