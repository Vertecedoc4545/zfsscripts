#!/bin/bash

# Run in chroot


# Add the Arch ZFS repository to /etc/pacman.conf
echo "
[archzfs]
Server = http://archzfs.com/$repo/x86_64
" >> /etc/pacman.conf

# sign its key
pacman-key -r 5E1ABF240EE7A126 && pacman-key --lsign-key 5E1ABF240EE7A126

# install zfs-linux
pacman -Syyu

# For /tmp, mask (disable) systemd's automatic tmpfs-backed /tmp
systemctl mask tmp.mount

## Install as normal ##
nano /etc/pacman.d/mirrorlist

# set locale, uncomment en_US.UTF-8 UTF-8
nano /etc/locale.gen
# generate the new locales
locale-gen

# set locale, LANG refers to the first column ofnano /etc/locale.conf
echo "LANG=es_MX.UTF-8" >> /etc/locale.conf

# timezone
ln -s  /usr/share/zoneinfo/Mexico/General /etc/localtime
# set the time standard to UTC
hwclock --systohc --utc

## Bootloader ##
# re-generate the initramfs image
mkinitcpio -p linux
# If intel cpu, set ucode as the first initrd in the bootloader
pacman -S intel-ucode
# Install systemd-boot to wherever esp mounted
bootctl --path=/boot install
echo "
# Bootloader entry
title    Arch Linux
linux    /vmlinuz-linux
initrd    /intel-ucode.img
initrd    /initramfs-linux.img
options   zfs=vault/ROOT/default rw

" >> /loader/entries/Arch.conf

## Configure the network ##
# Set the hostname to your liking:
echo "zfsDePrueva" >> /etc/hostname
echo "
## /etc/hosts: static lookup table for host names
## <ip-address>   <hostname.domain.org>   <hostname>
 127.0.0.1       localhost.localdomain   localhost
 ::1             localhost.localdomain   localhost
 127.0.1.1	  Archon.localdomain      zfsDePrueva
" >> /etc/hosts


# get nic
ip link
# enable internet
systemctl enable dhcpcd@eno1.service
systemctl enable NetworkManager.service
echo "root pass"
passwd

# Set either shutdown hook or this
systemctl enable mkinitcpio-generate-shutdown-ramfs.service

## Install Done, Customize ##
# Make a user
pacman -S fish 
wherisfish= $(which fish)
useradd -m -G wheel -s $wherisfish vertecedoc
passwd vertecedoc
EDITOR=nvim
pacman -S openssh git lynx
systemctl enable sshd

# Done!
exit

umount /mnt/boot
umount /mnt/home                                                                                                              
umount /mnt/tmp
umount /mnt/usr
umount /mnt/var

zfs umount -a
zpool export zroot

## Reboot!
