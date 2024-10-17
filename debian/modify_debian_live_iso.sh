#!/bin/bash

# Check if an ISO file is given
if [ $# -ne 1 ]; then
    echo "Usage: $0 <path_to_live_iso>"
    exit 1
fi

ISO_FILE=$(realpath -s $1)
CURRENT_DATE=$(date +%Y%m%d)

mkdir /tmp/cursed_dvd
cd /tmp/cursed_dvd
sudo umount new_root
sudo umount root_mount
sudo umount iso_mount
sudo umount *
sudo rm new_root/dev
sudo rm new_root/var/cache/apt
sudo rm -r *

mkdir iso_mount root_mount root_overlay_upper root_overlay_work new_root new_iso

sudo mount -o loop "$ISO_FILE" iso_mount
sudo mount iso_mount/live/filesystem.squashfs root_mount -t squashfs -o loop
sudo mount -t overlay -o lowerdir=root_mount,upperdir=root_overlay_upper,workdir=root_overlay_work overlay new_root

sudo mv new_root/dev new_root/fs_dev
sudo ln -s /dev new_root/
sudo mv new_root/var/cache/apt new_root/var/cache/fs_apt
sudo ln -s /var/cache/apt new_root/var/cache/apt

sudo chroot new_root systemctl mask avahi-daemon fwupd cups-browsed cupsd 
sudo chroot new_root apt autoremove --purge exim4-base bluez-firmware xiterm+thai gnome-games fcitx* fonts-thai-tlwg
sudo rm new_root/usr/share/desktop-base/*/*/contents/images/*.svg
sudo rm -r new_root/usr/share/sounds/*

sudo chroot new_root apt install chromium bash-completion qemu-system-x86 git xorriso wodim

sudo rm new_root/dev
sudo rm new_root/var/cache/apt
sudo mv new_root/fs_dev new_root/dev
sudo mv new_root/var/cache/fs_apt new_root/var/cache/apt

mkdir -p new_iso/live/
sudo mksquashfs new_root new_iso/live/filesystem.squashfs -comp zstd -b 1024K
mkdir -p new_iso/boot/grub/
sed -e "s|800x600|1920x1080|g" -f iso_mount/boot/grub/config.cfg > new_iso/boot/grub/config.cfg
