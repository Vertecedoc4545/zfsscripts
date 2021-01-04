#!/bin/bash

# Run in chroot
# arch-chroot /mnt /bin/bash

# Add the Arch ZFS repository to /etc/pacman.conf
nano /etc/pacman.conf
# [archzfs]
# Server = http://archzfs.com/$repo/x86_64

# sign its key
pacman-key -r 5E1ABF240EE7A126 && pacman-key --lsign-key 5E1ABF240EE7A126

# install zfs-linux
pacman -Syyu
pacman -S  zfs-linux-git

# For /tmp, mask (disable) systemd's automatic tmpfs-backed /tmp
systemctl mask tmp.mount

## Install as normal ##
nano /etc/pacman.d/mirrorlist

# set locale, uncomment en_US.UTF-8 UTF-8
nano /etc/locale.gen
# generate the new locales
locale-gen

# set locale, LANG refers to the first column of locale
nano /etc/locale.conf
# LANG=en_US.UTF-8

# timezone
ln -s  /usr/share/zoneinfo/Canada/Pacific /etc/localtime
# set the time standard to UTC
hwclock --systohc --utc

## Bootloader ##
# re-generate the initramfs image
mkinitcpio -p linux
# If intel cpu, set ucode as the first initrd in the bootloader
pacman -S intel-ucode
# Install systemd-boot to wherever esp mounted
bootctl --path=/boot install

# Bootloader entry
# title    Arch Linux
# linux    /vmlinuz-linux
# initrd    /intel-ucode.img
# initrd    /initramfs-linux.img
# options   zfs=vault/ROOT/default rw
nano /loader/entries/Arch.conf

## Configure the network ##
# Set the hostname to your liking:
nano /etc/hostname

## /etc/hosts: static lookup table for host names
## <ip-address>   <hostname.domain.org>   <hostname>
# 127.0.0.1       localhost.localdomain   localhost
# ::1             localhost.localdomain   localhost
# 192.168.0.2     Archon.localdomain      Archon
nano /etc/hosts


# get nic
ip link
# enable internet
systemctl enable dhcpcd@eno1.service

# root pass
passwd

# Set either shutdown hook or this
systemctl enable mkinitcpio-generate-shutdown-ramfs.service

## Install Done, Customize ##
# Make a user
pacman -S zsh sudo
useradd -m -G wheel -s /usr/bin/zsh john
passwd john
EDITOR=nano visudo
nano /etc/pacman.conf
pacman -S openssh
systemctl enable sshd
nano /etc/ssh/sshd_config

# Done!
exit

umount /mnt/boot
umount /mnt/home                                                                                                                 umount /mnt/tmp
umount /mnt/usr
umount /mnt/var

zfs umount -a
zpool export vault

## Reboot!
