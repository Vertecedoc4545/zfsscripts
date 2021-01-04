#!/bin/bash
# Check before running, may need intervention

# Pass in the following to the script, or hardcode it.

# Uncomment if hardcoding input.
cfdisk 

BOOT_PARTITION="/dev/sda1"
DISK_1="/dev/disk/by-id/ata-VBOX_HARDDISK_VBb8db763b-50d817d5-part2"
POOL="zroot"

# Check for zfs
curl -s https://eoli3n.github.io/archzfs/init | bash
modprobe zfs

# Create pool
zpool create -f -o ashift=9 -O acltype=posixacl -O relatime=on -O xattr=sa -O dnodesize=legacy -O normalization=formD -O mountpoint=none -O canmount=off -O devices=off -O compression=lz4 -R /mnt ${POOL} ${DISK_1}

## Properties
# Compression
# Access time
# Create key datasets
zfs create -o mountpoint=none ${POOL}/data
zfs create -o mountpoint=none ${POOL}/ROOT
zfs create -o mountpoint=/ -o canmount=noauto ${POOL}/ROOT/default
zfs create -o mountpoint=/home ${POOL}/data/home

## Optional datasets ##
# tmp
zfs create "${POOL}/tmp" \
                -o setuid=off \
                -o devices=off \
                -o sync=disabled \
                -o mountpoint=/tmp

# Mask systemd’s automatic tmpfs-backed tmp
systemctl mask tmp.mount
# var
zfs create -o mountpoint=/var -o canmount=off     ${POOL}/var
zfs create -o mountpoint=/var/lib -o canmount=off ${POOL}/var/lib
## End Optional

# Unmount pool
zfs umount -a

# Put them in /etc/fstab

# set boot property

## Setup Installation ##

# Export the pool
zpool export ${POOL}

# re-import the pool,
zpool import -d /dev/disk/by-id -R /mnt ${POOL} -N

#  bring the zpool.cache file into your new system
#cp /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache
# OR, if you do not have /etc/zfs/zpool.cache, create it:

# Mount legacy zfs
mount -t zfs ${POOL}/ROOT/default /mnt
mount -t zfs ${POOL}/data/home /mnt/home
mount -t zfs ${POOL}/var /mnt/var
mount -t zfs ${POOL}/var/lib /mnt/var/lib
mount -t zfs ${POOL}/usr /mnt/usr
mount -t zfs ${POOL}/tmp /mnt/tmp

mkdir -p /mnt/etc/zfs

zpool set cachefile=/etc/zfs/zpool.cache ${POOL}

cp /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache

# Boot
mkdir -p /mnt/boot/EFI
mount ${BOOT_PARTITION} /mnt/boot/EFI

# Generate the fstab
genfstab -U -p /mnt >> /mnt/etc/fstab

# Comment out all non-legacy datasets apart from the root dataset,
# the swap file and the boot/EFI partition.
# Edit mirrorlist
cat /etc/pacman.d/mirrorlist >> /mnt/etc/pacman.d/mirrorlist

# Install the base system
pacstrap -i /mnt base base-devel linux neovim linux-headers mkinitcpio-sd-zfs dhcp nerworkmanager

# Edit ramdisk hooks
# If you are using a separate dataset for /usr, have the usr hook enabled after zfs
# If using a separate dataset for /var, add shutdowm hook
echo "HOOKS="base udev autodetect modconf block keyboard sd-zfs filesystems"" >> /mnt/etc/mkinitcpio.conf

mv zfsinstall-2.sh /mnt
# Enter chroot
