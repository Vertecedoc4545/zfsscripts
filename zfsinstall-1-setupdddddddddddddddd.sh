
# Check for zfs
modprobe zfs

# Create pool
zpool create -f -o ashift=12 ${POOL} ${DISK_1} 

## Properties
# Compression
zfs set compression=on ${POOL}
# Access time
zfs set atime=on ${POOL}
zfs set relatime=on ${POOL}

# Create key datasets
zfs create -o mountpoint=none "${POOL}/ROOT"
zfs create -o mountpoint=legacy "${POOL}/ROOT/default"
zfs create -o mountpoint=/home "${POOL}/home"

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
zfs create "${POOL}/var" \
                -o xattr=sa \
                -o mountpoint=legacy

# usr
zfs create "${POOL}/usr" -o mountpoint=legacy
## End Optional

# Unmount pool
zfs umount -a

# Put them in /etc/fstab
echo "
# <pass><file system> <dir> <type> <options> <dump>
# zroot/ROOT/default   /       zfs     rw,relatime,xattr,noacl     0 0
# zroot/var            /var    zfs     rw,relatime,xattr,noacl     0 0
# zroot/usr            /usr    zfs     rw,relatime,xattr,noacl     0 0
" >> etc/fstab
# set boot property
zpool set bootfs="${POOL}/ROOT/default" ${POOL}

## Setup Installation ##

# Export the pool
zpool export ${POOL}

# re-import the pool,
zpool import -d /dev/disk/by-id -R /mnt ${POOL}

#  bring the zpool.cache file into your new system
mkdir -p /mnt/etc/zfs
#cp /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache
# OR, if you do not have /etc/zfs/zpool.cache, create it:
zpool set cachefile=/etc/zfs/zpool.cache zroot
cp /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache

# Mount legacy zfs
mkdir /mnt/{home,var,usr,tmp,boot}
mount -t zfs "${POOL}/home" "/mnt/home"
mount -t zfs "${POOL}/var" "/mnt/var"
mount -t zfs "${POOL}/usr" "/mnt/usr"
mount -t zfs "${POOL}/tmp" "/mnt/tmp"

# Boot
mkdir -p /boot
mount "/dev/${BOOT_PARTITION}" /boot

# Generate the fstab
genfstab -U -p /mnt >> /mnt/etc/fstab

# Comment out all non-legacy datasets apart from the root dataset,
# the swap file and the boot/EFI partition.
nano /mnt/etc/fstab

# Edit mirrorlist
nano /etc/pacman.d/mirrorlist

# Install the base system
pacstrap -i /mnt base base-devel linux neovim linux-headers

# Edit ramdisk hooks
# If you are using a separate dataset for /usr, have the usr hook enabled after zfs
# If using a separate dataset for /var, add shutdowm hook
echo "HOOKS="base udev autodetect modconf block keyboard zfs usr filesystems shutdown"" >> /mnt/etc/mkinitcpio.conf

# Enter chroot
