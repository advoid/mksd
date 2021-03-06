#!/bin/bash

# Written 2015 by Johannes Findeisen <you@hanez.org>
# Licensed under the terms of the GPLv2 license.
#
# This needs to run as root!
#
# Use this only if you know what you're doing.

DEVICE=/dev/mmcblk0
HOSTNAME=advoid
TMPDIR=`mktemp -d --suffix=.$$`
TIMEZONE=Europe/Berlin
BOOTSIZE=100M
ROOTSIZE=2800M
STAGE3DATE=20150730
STAGE3SOURCE=http://advoid.net/files
PORTAGEDATE=20150819
PORTAGESOURCE=http://advoid.net/files

# Create partitions: 
echo -e "d\n\nd\n\nd\no\nn\np\n1\n\n+${BOOTSIZE}\nn\np\n2\n\n+${ROOTSIZE}\nn\np\n3\n\n\nt\n1\nc\nt\n3\n82\nw" | fdisk ${DEVICE}

# Prepare filesystems:
mkfs.msdos -F 32 ${DEVICE}p1 -n ADVOID_BOOT
mke2fs -F -t ext4 -N 803200 ${DEVICE}p2 -L ADVOID_ROOT
mkswap ${DEVICE}p3

# Mount filesystems:
mkdir ${TMPDIR}
mount ${DEVICE}p2 ${TMPDIR}
mkdir ${TMPDIR}/boot
mount ${DEVICE}p1 ${TMPDIR}/boot

mkdir tmp
cd tmp

# Extract Gentoo
echo "Extracting Gentoo stage3"
if [ ! -f ./stage3-armv6j_hardfp-${STAGE3DATE}.tar.bz2 ]
then
  echo "Downloading file..."
  wget ${STAGE3SOURCE}/stage3-armv6j_hardfp-${STAGE3DATE}.tar.bz2
fi
echo "Extracting file"
tar xfpj stage3-armv6j_hardfp-${STAGE3DATE}.tar.bz2 -C ${TMPDIR}/

echo "Extracting Portage tree"
if [ ! -f ./portage-${PORTAGEDATE}.tar.bz2 ]
then
  echo "Downloading file..."
  wget ${PORTAGESOURCE}/portage-${PORTAGEDATE}.tar.bz2
fi
echo "Extracting file"
tar xjf portage-${PORTAGEDATE}.tar.bz2 -C ${TMPDIR}/usr/

# Install kernel
echo "Installing Kernel"
if [ ! -d ./firmware ]
then
  git clone --depth 1 git://github.com/advoid/firmware/
fi
cd firmware/boot
cp * ${TMPDIR}/boot/
cp -r ../modules ${TMPDIR}/lib/ 

# Configure the system:
echo "Configuring the system"

# /etc/fstab
cat << EOF > ${TMPDIR}/etc/fstab
/dev/mmcblk0p1      /boot       auto        noauto,noatime  1 2
/dev/mmcblk0p2      /           ext4        noatime         0 1
/dev/mmcblk0p3      none        swap        sw              0 0
EOF

# /boot/cmdline.txt
cat << EOF > ${TMPDIR}/boot/cmdline.txt
dwc_otg.lpm_enable=0 console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline smsc95xx.turbo_mode=N rootwait
EOF

# Timezone
cp ${TMPDIR}/usr/share/zoneinfo/${TIMEZONE} ${TMPDIR}/etc/localtime
echo ${TIMEZONE} > ${TMPDIR}/etc/timezone

# Networking, hostname and swclock
cd ${TMPDIR}/etc/init.d/
cp net.lo net.eth0
ln -s /etc/init.d/net.eth0 ../runlevels/boot/net.eth0
echo "hostname=\"${HOSTNAME}\"" > ${TMPDIR}/etc/conf.d/hostname
rm -f ../runlevels/boot/hwclock
ln -s /etc/init.d/swclock ../runlevels/boot/swclock
ln -s /etc/init.d/sshd ../runlevels/default/sshd

# Enable TTY on ttyAMA0 for a serial interface to advoid.
echo "#Spawn a getty on Raspberry Pi serial line" >> ${TMPDIR}/etc/inittab
echo "T0:23:respawn:/sbin/agetty -L ttyAMA0 115200 vt100" >> ${TMPDIR}/etc/inittab

cat << EOF > ${TMPDIR}/boot/config.txt
arm_freq=900
core_freq=333
sdram_freq=450
over_voltage=2
EOF

touch ${TMPDIR}/boot/test.touch

# Cleanup:
echo "Cleaning up and unmounting filesystems"
cd /tmp
umount ${TMPDIR}/boot
umount ${TMPDIR}
rm -rf ${TMPDIR}

