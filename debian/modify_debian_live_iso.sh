#!/bin/bash

sudo apt-get install xorriso

CURSED=$(realpath -s ..)
CURRENT_DATE=$(date +%Y%m%d)
test_boot=0

prefix=""
target="/"
for arg in "$@"; do
  case $arg in 
    test_boot=*) test_boot=$(echo $arg|sed "s/[^=]*=//");;
    iso=*) iso=$(echo $arg|sed "s/[^=]*=//");;
  esac
done
# Check if an ISO file is given
if [ $iso -ne 1 ]; then
    echo "Usage: $0 iso=<path_to_live_iso>"
    exit 1
fi

ISO_FILE=$(realpath -s $iso)

mkdir /tmp/cursed_dvd
cd /tmp/cursed_dvd
sudo umount new_root/dev
sudo umount new_root/var/cache/apt
sudo umount new_root
sudo umount root_mount
sudo umount iso_mount
sudo umount *
sudo rm -r *

mkdir iso_mount root_mount root_overlay_upper root_overlay_work new_root new_iso

sudo mount -o loop "$ISO_FILE" iso_mount
sudo mount iso_mount/live/filesystem.squashfs root_mount -t squashfs -o loop
sudo mount -t overlay -o lowerdir=root_mount,upperdir=root_overlay_upper,workdir=root_overlay_work overlay new_root

sudo mount -o bind /dev new_root/dev
sudo mount -o bind /var/cache/apt new_root/var/cache/apt


if [ $test_boot -eq 0 ]; then
  sudo chroot new_root bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y adb bash-completion bmap-tools chromium espeak-ng fastboot gimp git ibus-pinyin mpv nodejs npm qemu-system-x86 wireshark wodim xorriso obs-studio python3-pip python3-socks"

  if sha256sum $CURSED/debian/cnijfilter2-6.71-1-deb.1a0080b3ee4b2d20a764f5ba5ff4bfd49be6f487b7ebbd9e5996290c29b7d9c2.tar.gz | cut -d " " -f 1| grep 1a0080b3ee4b2d20a764f5ba5ff4bfd49be6f487b7ebbd9e5996290c29b7d9c2; then
    tar -xvf $CURSED/debian/cnijfilter2-6.71-1-deb.1a0080b3ee4b2d20a764f5ba5ff4bfd49be6f487b7ebbd9e5996290c29b7d9c2.tar.gz cnijfilter2-6.71-1-deb/packages/cnijfilter2_6.71-1_amd64.deb --one-top-level=new_root --strip-components 2
    sudo chroot new_root apt install -y /cnijfilter2_6.71-1_amd64.deb
    rm new_root/cnijfilter2_6.71-1_amd64.deb
  fi
fi
#TODO: find a way to do this without network
#sudo chroot new_root npm i pagecage

sudo chroot new_root systemctl mask avahi-daemon fwupd cups-browsed 
sudo sed -i new_root/var/lib/dpkg/info/bluez.prerm -e "s|invoke-rc.d|echo invoke-rc.d|"
sudo chroot new_root apt autoremove --purge -y bluez bluez-firmware bluez-obexd cups-browsed debian-reference-common exim4-base fcitx* fonts-thai-tlwg fortunes-debian-hints gnome-games gnome-online-accounts gnome-initial-setup gnome-music gnome-software gnome-sushi gnome-themes-extra pinentry-gnome3 totem xiterm+thai yelp
sudo chroot new_root bash -c 'apt list --installed|cut -d / -f 1|grep -e "l10n-[a-z]"|xargs apt autoremove --purge -y '
sudo chroot new_root bash -c 'apt list --installed|cut -d / -f 1|grep -e "spell-[a-z]"|grep -v -e -en|xargs apt autoremove --purge -y '
sudo chroot new_root bash -c 'apt list --installed|cut -d / -f 1|grep manpages-| xargs apt autoremove --purge -y'
sudo chroot new_root bash -c 'apt list --installed|cut -d / -f 1|grep -e fonts-lohit -e fonts-be -e fonts-t -e fonts-smc| xargs apt autoremove --purge -y'
sudo chroot new_root bash -c 'apt list --installed|cut -d / -f 1|grep -e "mythes-[a-df-z]"|xargs apt autoremove --purge -y'
sudo chroot new_root bash -c 'apt list --installed|cut -d / -f 1|grep "^task-"|grep -v -e english -e laptop| xargs apt autoremove --purge -y'
echo "n"|sudo chroot new_root apt remove ispell |grep "^  "|sed -e "s|ispell||" -e "s|ieng[a-z-]* ||" -e "s|iamer[a-z-]* ||"|xargs sudo chroot new_root apt autoremove --purge -y
#sudo chroot new_root bash -c 'apt list --installed|cut -d / -f 1|grep "^task-"|grep -v -e english -e laptop| xargs -L 1 dpkg -L | tr "\n" "#"|sed -e "s|#[^#]*#pack[^#]*||g"|tr "#" "\n" | xargs rm' 2>&1|grep -v "Is a directory"

sudo cp $CURSED/hood/scripts/hosts new_root/etc/
sudo cp $CURSED/hood/scripts/NetworkManager.conf new_root/etc/NetworkManager/NetworkManager.conf
sudo cp $CURSED/hood/scripts/ca-certificates.conf new_root/etc/
sudo cp $CURSED/hood/scripts/sysctl.conf new_root/etc/
sudo mkdir -p new_root/etc/pki/
sudo cp -r $CURSED/hood/scripts/nssdb new_root/etc/pki/
sudo chroot new_root gsettings set org.gnome.desktop.thumbnailers disable-all true


#sudo chmod -x new_root/usr/sbin/dhclient

sudo rm new_root/usr/share/desktop-base/*/*/contents/images/*.svg
sudo rm -r new_root/usr/share/sounds/*

sudo umount new_root/dev
sudo umount new_root/var/cache/apt

mkdir -p new_iso/boot/grub/
sed -e "s|800x600|1920x1080|g" iso_mount/boot/grub/config.cfg > new_iso/boot/grub/config.cfg
sed -e "s|findiso=.*|nodhcp efi=noruntime module_blacklist=i2c_piix4,i2c_smbios,msr,parport,qrtr,intel_rapl_common,serio_raw initcall_blacklist=serial_base_port_init|g" iso_mount/boot/grub/grub.cfg > new_iso/boot/grub/grub.cfg
#verify-checksums 

mkdir -p new_iso/live/
sudo mksquashfs new_root new_iso/live/filesystem.squashfs -comp zstd -b 512K -Xcompression-level 22

cat iso_mount/md5sum.txt | grep -v -e " ./install" -e " ./pool" -e " ./dists" > md5sum.txt
cat iso_mount/sha256sum.txt | grep -v -e " ./install" -e " ./pool" -e " ./dists" > sha256sum.txt
#new hashes
find new_iso/ -type f -exec bash -c "iso_path=\$(echo {}|sed -e 's|new_iso|\\.|');hash=\$(sha256sum {}|cut -d ' ' -f 1);sed -i sha256sum.txt -e 's|.*\$iso_path\$|\$hash \$iso_path|';" \;
find new_iso/ -type f -exec bash -c "iso_path=\$(echo {}|sed -e 's|new_iso|\\.|');hash=\$(md5sum {}|cut -d ' ' -f 1);sed -i md5sum.txt -e 's|.*\$iso_path\$|\$hash \$iso_path|';" \;
mv md5sum.txt new_iso/
mv sha256sum.txt new_iso/

xorriso -boot_image any keep -indev "$ISO_FILE" -outdev cursed.iso  -map new_iso / -rm_r /install -rm_r /pool -rm_r /dists -rm_r /pool-udeb

cd -
mv /tmp/cursed_dvd/cursed.iso cursed-$(date "+%Y%m%d%H%M%S")-`sha256sum /tmp/cursed_dvd/cursed.iso | cut -d " " -f 1`.iso
