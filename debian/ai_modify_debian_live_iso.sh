#!/bin/bash

# Check if an ISO file is given
if [ $# -ne 1 ]; then
    echo "Usage: $0 <path_to_live_iso>"
    exit 1
fi

ISO_FILE=$1
ISO_DIR=$(mktemp -d)
WORK_DIR=$(mktemp -d)
CURRENT_DATE=$(date +%Y%m%d)
OUTPUT_ISO="temp_modified.iso"

# Step 1: Mount the ISO
echo "Mounting ISO..."
sudo mount -o loop "$ISO_FILE" "$ISO_DIR"

# Step 2: Extract filesystem.squashfs
echo "Extracting filesystem.squashfs..."
sudo cp "$ISO_DIR/live/filesystem.squashfs" "$WORK_DIR/"

# Step 3: Uncompress filesystem.squashfs
echo "Uncompressing filesystem.squashfs..."
sudo unsquashfs -d "$WORK_DIR/filesystem_dir" "$WORK_DIR/filesystem.squashfs"

# Step 4: Remove Avahi and CUPS services
echo "Removing Avahi and CUPS services from the filesystem..."
if [ -f "$WORK_DIR/filesystem_dir/etc/apt/sources.list" ]; then
    echo "Updating package list and removing avahi-daemon and cups..."
    sudo chroot "$WORK_DIR/filesystem_dir" /bin/bash -c "apt-get update && apt-get remove --purge avahi-daemon cups -y"
else
    echo "No package manager found. Removing avahi and cups files manually."
    sudo rm -rf "$WORK_DIR/filesystem_dir/etc/avahi"
    sudo rm -rf "$WORK_DIR/filesystem_dir/usr/sbin/avahi-daemon"
    sudo rm -rf "$WORK_DIR/filesystem_dir/usr/share/avahi"
    sudo rm -rf "$WORK_DIR/filesystem_dir/lib/systemd/system/avahi-daemon.service"
    sudo rm -rf "$WORK_DIR/filesystem_dir/etc/cups"
    sudo rm -rf "$WORK_DIR/filesystem_dir/usr/sbin/cupsd"
    sudo rm -rf "$WORK_DIR/filesystem_dir/usr/share/cups"
    sudo rm -rf "$WORK_DIR/filesystem_dir/lib/systemd/system/cups.service"
fi

# Step 5: Remove kernel modules
echo "Removing specified kernel modules..."
KERNEL_MODULES=("amd_pmc" "parport" "i2c_piix4" "i2c_smbios" "wmi" "msr")
for MODULE in "${KERNEL_MODULES[@]}"; do
    sudo rm -f "$WORK_DIR/filesystem_dir/lib/modules/*/kernel/drivers/firmware/${MODULE}.ko" \
               "$WORK_DIR/filesystem_dir/lib/modules/*/kernel/drivers/parport/${MODULE}.ko" \
               "$WORK_DIR/filesystem_dir/lib/modules/*/kernel/drivers/i2c/${MODULE}.ko" \
               "$WORK_DIR/filesystem_dir/lib/modules/*/kernel/drivers/${MODULE}.ko" \
               "$WORK_DIR/filesystem_dir/lib/modules/*/kernel/firmware/${MODULE}.ko"
done

# Step 6: Modify GRUB configuration for resolution
echo "Modifying GRUB configuration for resolution 1366x768..."
GRUB_CFG="$ISO_DIR/boot/grub/config.cfg"
if [ -f "$GRUB_CFG" ]; then
    sudo sed -i 's/set gfxmode=800x600/set gfxmode=1366x768/' "$GRUB_CFG"
else
    echo "GRUB configuration file not found!"
fi

# Step 7: Modify grub.cfg for new menuentry
echo "Modifying grub.cfg to add a menu entry named 'yongbin'..."
GRUB_CFG_FILE="$ISO_DIR/boot/grub/grub.cfg"
if [ -f "$GRUB_CFG_FILE" ]; then
    sudo cp "$GRUB_CFG_FILE" "$GRUB_CFG_FILE.bak"  # Backup original config
    sudo awk -v new_entry='yongbin' '
    /menuentry "Live system (amd64)"/ { 
        print; 
        print "    menuentry \"" new_entry "\" {";
        print "        linux /live/vmlinuz boot=live components quiet noapic noapm nodma nomce nosmp nosplash ipv6.disable=1 efi=noruntime";
        print "        initrd /live/initrd.img";
        print "    }";
        next; 
    }1' "$GRUB_CFG_FILE" | sudo tee "$GRUB_CFG_FILE.new" > /dev/null
    sudo mv "$GRUB_CFG_FILE.new" "$GRUB_CFG_FILE"
else
    echo "grub.cfg file not found!"
fi

# Step 8: Repack filesystem.squashfs
echo "Repacking filesystem.squashfs..."
sudo mksquashfs "$WORK_DIR/filesystem_dir" "$WORK_DIR/filesystem.squashfs" -comp xz -b 1024K

# Step 9: Create a temporary new ISO with the modified filesystem.squashfs
echo "Creating temporary ISO with modified filesystem.squashfs..."
sudo cp "$WORK_DIR/filesystem.squashfs" "$ISO_DIR/live/"
sudo xorriso -as mkisofs \
    -r -V "Modified Live ISO" \
    -o "$OUTPUT_ISO" \
    -J -joliet-long \
    -isolation \
    -graft-points \
    "$ISO_DIR"

# Get SHA256 of the new ISO
SHA256_HASH=$(sha256sum "$OUTPUT_ISO" | awk '{ print $1 }')
FINAL_OUTPUT_ISO="modified-${CURRENT_DATE}-${SHA256_HASH}.iso"

# Step 10: Rename the temporary ISO to include SHA256
mv "$OUTPUT_ISO" "$FINAL_OUTPUT_ISO"

# Step 11: Cleanup
echo "Cleaning up..."
sudo umount "$ISO_DIR"
rm -rf "$ISO_DIR" "$WORK_DIR"

echo "Modified ISO created: $FINAL_OUTPUT_ISO"

# Comments
# create a script to extract /live/filesystem.squashfs iso. and then remove avahi and cups services from filesystem.squashfs and also remove amd_pmc,parport, i2c_piix4,i2c_smbios,wmi,msr kernel modules from it. then add modified filesystem.squashfs back to original iso to build a new iso with current date and sha256 value of the new iso added to its filename. modify the grub configuration file /boot/grub/config.cfg in the iso to use 1366x768 resolution instead of 800x600. modify grub configuration file /boot/grub/grub.cfg copy the content of the menuentry a menu entry "Live system (amd64)" to menuentry named yongbin and change the kernel command line to "boot=live components quiet noapic noapm nodma nomce nosmp nosplash ipv6.disable=1 efi=noruntime". do not explain how to use it. add all my words, including this sentence, to the end of the file as a comment starts with #
