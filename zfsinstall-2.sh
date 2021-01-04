#!/bin/bash

# Run in chroot


# Add the Arch ZFS repository to /etc/pacman.conf
echo "adding repo archzfs"
pacman -Sy archlinux-keyring --noconfirm &>/dev/null
pacman-key --populate archlinux &>/dev/null
pacman-key --recv-keys F75D9D76 --keyserver keyserver.ubuntu.com &>/dev/null
pacman-key --lsign-key F75D9D76 &>/dev/null
cat>>/etc/pacman.conf<<"EOF"
[archzfs]
Server = http://archzfs.com/archzfs/x86_64
Server = http://mirror.sum7.eu/archlinux/archzfs/x86_64
Server = https://mirror.biocrafting.net/archlinux/archzfs/archzfs/x86_64
EOF
pacman -Sy &>/dev/null

# sign its key

# install zfs-linux
pacman -Syyu

# For /tmp, mask (disable) systemd's automatic tmpfs-backed /tmp

## Install as normal ##

# set locale, uncomment en_US.UTF-8 UTF-8
echo "LANG=es_MX.UTF-8" >> /etc/locale.gen
# generate the new locales
locale-gen

# set locale, LANG refers to the first column ofnano /etc/locale.conf
echo "LANG=es_MX.UTF-8" >> /etc/locale.conf

# timezone
ln -s  /usr/share/zoneinfo/Mexico/General /etc/localtime
# set the time standard to UTC
hwclock --systohc --utc

echo "KEYMAP=la-latin1" >> /etc/vconsole.conf

## Bootloader ##
# re-generate the initramfs image
# If intel cpu, set ucode as the first initrd in the bootloader
pacman -S intel-ucode
mkinitcpio -P
# Install systemd-boot to wherever esp mounted
bootctl --path=/boot install
echo "
# Bootloader entry
title    Arch Linux
linux    /vmlinuz-linux
initrd    /intel-ucode.img
initrd    /initramfs-linux.img
options   zfs=zroot/ROOT/default rw

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
pacman -S openssh git lynx grub efibootmgr
systemctl enable sshd

grub-install --target=x86_64-efi --efi-directory=esp --bootloader-id=GRUB

grub-mkconfig -o /boot/grub/grub.cfg

ZPOOL_VDEV_NAME_PATH=1 grub-mkconfig -o /boot/grub/grub.cfg
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
