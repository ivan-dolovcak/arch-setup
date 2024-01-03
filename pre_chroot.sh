#!/usr/bin/sh

set -e # Exit on error.

## GLOBALS
##
targetDevice=$1

## PARTITIONING
##
# Optional disk shredding, use more iterations for HDD's: 
# shred --verbose --force --iterations=1 --zero "$targetDevice"
# "--zero" is used to fill the device with zeroes to hide the shredding itself,
# such that the target disk will look like a brand new, unused medium.

# Destroy the GPT scheme:
sgdisk --zap-all "$targetDevice"
# alt command: wipefs --all --force "$targetDevice"

# Repartition:
sfdisk "$targetDevice" < disk_dump.txt

# TODO: generalize formatting and mounting for scripting.
# Format:
mkfs.fat -F 32 /dev/disk/by-partlabel/ESP
mkfs.ext4 /dev/disk/by-partlabel/root
mkfs.ext4 /dev/disk/by-partlabel/home
mkswap /dev/disk/by-partlabel/swap
swapon /dev/disk/by-partlabel/swap

# Mount:
mount /dev/disk/by-partlabel/root /mnt
mount --mkdir /dev/disk/by-partlabel/ESP /mnt/boot
mount --mkdir /dev/disk/by-partlabel/home /mnt/home

# Make fstab:
mkdir /mnt/etc
genfstab -U /mnt > /mnt/etc/fstab # -U -> use UUID's

# Update pacman mirrors:
reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

# Install Arch Linux with specified packages:
pacstrap -K /mnt - < pkglist_native.txt # -K -> init empty pacman keyring

# Copy repo into root jail instead of recloning later:
scriptsDir="$(pwd)"
cp -r "$scriptsDir" /mnt

arch-chroot /mnt "/$(basename $scriptsDir)/post_chroot.sh"

reboot
