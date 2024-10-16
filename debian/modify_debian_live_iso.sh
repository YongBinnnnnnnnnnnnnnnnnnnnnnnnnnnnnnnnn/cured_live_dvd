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
sudo rm -r *
sudo rm new_root/dev


mkdir iso_mount root_mount root_overlay_upper root_overlay_work new_root

sudo mount -o loop "$ISO_FILE" iso_mount
sudo mount iso_mount/live/filesystem.squashfs root_mount -t squashfs -o loop
sudo mount -t overlay -o lowerdir=root_mount,upperdir=root_overlay_upper,workdir=root_overlay_work overlay new_root
sudo mv new_root/dev new_root/fs_dev
sudo ln -s /dev new_root/



