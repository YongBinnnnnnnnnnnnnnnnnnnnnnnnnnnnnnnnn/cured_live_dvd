#!/bin/bash

sudo apt-get install xorriso

CURSED=$(realpath -s ..)
CURRENT_DATE=$(date +%Y%m%d)
test_boot=1
skip_fs=0
skip_install=0
skip_remove=0
fast_comp=0
debug=0

prefix=""
squashfs_compression="-comp zstd -Xcompression-level 22"
for arg in "$@"; do
  case $arg in 
    iso=*) iso=$(echo $arg|sed "s/[^=]*=//");;
    debug=*) debug=$(echo $arg|sed "s/[^=]*=//");;
    fast_comp=*) fast_comp=$(echo $arg|sed "s/[^=]*=//");;
    skip_fs=*) skip_fs=$(echo $arg|sed "s/[^=]*=//");;
    skip_install=*) skip_install=$(echo $arg|sed "s/[^=]*=//");;
    skip_remove=*) skip_remove=$(echo $arg|sed "s/[^=]*=//");;
    test_boot=*) test_boot=$(echo $arg|sed "s/[^=]*=//");;
  esac
done

echo config $fast_comp $skip_fs $skip_install $test_boot

if [ $fast_comp -eq 1 ]; then
  squashfs_compression="-comp gzip -Xcompression-level 1"
fi

# Check if an ISO file is given
if ! test $iso; then
    echo "Usage: $0 iso=<path_to_live_iso>"
    exit 1
fi

if ! test $CURSED/hood; then
    echo "Could not find hood. Forgot init submodule or using the script out of project"
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
sudo umount * 2>/dev/null
sudo rm -r *

mkdir iso_mount root_mount root_overlay_upper root_overlay_work new_root new_iso

sudo mount -o loop "$ISO_FILE" iso_mount

if [ $skip_fs -ne 1 ]; then
  if [ $debug -eq 1 ]; then
    read -p "debug pause"
  fi
  sudo mount iso_mount/live/filesystem.squashfs root_mount -t squashfs -o loop
  sudo mount -t overlay -o lowerdir=root_mount,upperdir=root_overlay_upper,workdir=root_overlay_work overlay new_root

  sudo mount -o bind /dev new_root/dev
  sudo mount -o bind /var/cache/apt new_root/var/cache/apt


  if [ $skip_install -ne 1 ]; then
    sudo chroot new_root bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y adb bash-completion bmap-tools chromium espeak-ng fastboot gimp git ibus-pinyin mpv nodejs npm plymouth qemu-system-x86 wireshark wodim xorriso obs-studio python3-pip python3-socks mokutil openssl zip"

    if sha256sum $CURSED/debian/cnijfilter2-6.71-1-deb.1a0080b3ee4b2d20a764f5ba5ff4bfd49be6f487b7ebbd9e5996290c29b7d9c2.tar.gz | cut -d " " -f 1| grep 1a0080b3ee4b2d20a764f5ba5ff4bfd49be6f487b7ebbd9e5996290c29b7d9c2; then
      tar -xvf $CURSED/debian/cnijfilter2-6.71-1-deb.1a0080b3ee4b2d20a764f5ba5ff4bfd49be6f487b7ebbd9e5996290c29b7d9c2.tar.gz cnijfilter2-6.71-1-deb/packages/cnijfilter2_6.71-1_amd64.deb --one-top-level=new_root --strip-components 2
      sudo chroot new_root apt install -y /cnijfilter2_6.71-1_amd64.deb
      rm new_root/cnijfilter2_6.71-1_amd64.deb
    fi
  fi
  #TODO: find a way to do this without network
  #sudo chroot new_root npm i pagecage

  if [ $debug -eq 1 ]; then
    read -p "debug pause"
  fi

  sudo chroot new_root systemctl mask suspend.target fwupd cups-browsed 
  sudo sed -i new_root/var/lib/dpkg/info/bluez.prerm -e "s|invoke-rc.d|echo invoke-rc.d|"
  
  if [ $skip_remove -ne 1 ]; then
    sudo chroot new_root apt autoremove --purge -y bluez bluez-firmware bluez-obexd calamares cups-browsed debian-reference-common exim4-base firmware-ivtv firmware-netronome fonts-thai-tlwg fonts-noto-cjk-extra fonts-noto-extra fortunes-debian-hints gnome-games gnome-online-accounts gnome-initial-setup gnome-music gnome-software gnome-sushi gnome-themes-extra mlterm mlterm-tiny mlterm-tools pinentry-gnome3 rhythmbox shotwell totem vlc-l10n wnorwegian wpolish xiterm+thai yelp
    sudo chroot new_root bash -c 'apt list --installed|cut -d / -f 1|grep -e "fcitx"|xargs apt autoremove --purge -y '
    sudo chroot new_root bash -c 'apt list --installed|cut -d / -f 1|grep -e "l10n-[a-z]"|xargs apt autoremove --purge -y '
    sudo chroot new_root bash -c 'apt list --installed|cut -d / -f 1|grep -e "spell-[a-z]"|grep -v -e -en|xargs apt autoremove --purge -y '
    sudo chroot new_root bash -c 'apt list --installed|cut -d / -f 1|grep manpages-| xargs apt autoremove --purge -y'
    sudo chroot new_root bash -c 'apt list --installed|cut -d / -f 1|grep -e fonts-lohit -e fonts-be -e fonts-t -e fonts-smc| xargs apt autoremove --purge -y'
    sudo chroot new_root bash -c 'apt list --installed|cut -d / -f 1|grep -e "mythes-[a-df-z]"|xargs apt autoremove --purge -y'
    sudo chroot new_root bash -c 'apt list --installed|cut -d / -f 1|grep "^task-"|grep -v -e english -e laptop| xargs apt autoremove --purge -y'
    echo "n"|sudo chroot new_root apt remove ispell |grep "^  "|sed -e "s|ispell||" -e "s|ieng[a-z-]* ||" -e "s|iamer[a-z-]* ||"|xargs sudo chroot new_root apt autoremove --purge -y
    #sudo chroot new_root bash -c 'apt list --installed|cut -d / -f 1|grep "^task-"|grep -v -e english -e laptop| xargs -L 1 dpkg -L | tr "\n" "#"|sed -e "s|#[^#]*#pack[^#]*||g"|tr "#" "\n" | xargs rm' 2>&1|grep -v "Is a directory"
  fi
  
  if [ $debug -eq 1 ]; then
    read -p "debug pause"
  fi

  sudo cp $CURSED/os_neutral/hosts/hosts new_root/etc/
  sudo cp $CURSED/hood/scripts/NetworkManager.conf new_root/etc/NetworkManager/NetworkManager.conf
  sudo cp $CURSED/hood/scripts/ca-certificates.conf new_root/etc/
  sudo chroot new_root update-ca-certificates
  sudo cp $CURSED/hood/scripts/sysctl.conf new_root/etc/
  sudo mkdir -p new_root/etc/pki/
  sudo cp -r $CURSED/hood/scripts/nssdb new_root/etc/pki/
  
  sudo mkdir -p new_root/etc/dconf/db/live.d/
  sudo tee new_root/etc/dconf/profile/user <<EOF
user-db:user
system-db:live
EOF
  sudo tee new_root/etc/dconf/db/live.d/01-cursed <<EOF
[org/gnome/nautilus/preferences]
show-image-thumbnails='never'

[org/gnome/desktop/thumbnailers]
disable-all=true

[org/gnome/desktop/interface]
gtk-im-module='ibus'

[org/gnome/desktop/input-sources]
sources=[('xkb', 'us'), ('ibus', 'pinyin')]

EOF
  sudo chroot new_root dconf update
  sudo sed -i new_root/usr/bin/chromium -e 's|CHROMIUM_FLAGS=""|CHROMIUM_FLAGS=" --disable-features=MediaRouter"|'

  sudo mkdir -p new_root/lib/cursed/sbin
  sudo mv new_root/usr/sbin/dhclient new_root/lib/cursed/sbin/
  sudo cp $CURSED/linux/cursed_dhclient.sh new_root/usr/sbin/dhclient

  sudo chroot new_root rm /usr/share/desktop-base/*/*/contents/images/*.svg
  #sudo rm -r new_root/usr/share/sounds/*
  sudo rm -r new_root/usr/share/backgrounds/*

  sudo umount new_root/dev
  sudo umount new_root/var/cache/apt
  
  mkdir -p new_iso/live/
  
  if [ $debug -eq 1 ]; then
    read -p "debug pause"
  fi

  sudo mksquashfs new_root new_iso/live/filesystem.squashfs $squashfs_compression
fi

if [ $debug -eq 1 ]; then
  read -p "debug pause"
fi

mkdir -p new_iso/boot/grub/
sed -e "s|800x600|1920x1080|g" iso_mount/boot/grub/config.cfg > new_iso/boot/grub/config.cfg
sed -e "s|findiso=.*|toram=filesystem.squashfs nodhcp noapic efi=noruntime pnpbios=off pnpacpi=off module_blacklist=i2c_piix4,sp5100_tco,i2c_smbios,msr,parport,qrtr,intel_rapl_common,joydev,serio_raw,mei initcall_blacklist=tpm_init,serial8250_init acpiphp.disable=Y |g" iso_mount/boot/grub/grub.cfg > new_iso/boot/grub/grub.cfg
#useless: ccp.dmaengine=0 ccp.psp_init_on_probe=N ,serial_base_port_init
#verify-checksums 

cat iso_mount/md5sum.txt | grep -v -e " ./install" -e " ./pool" -e " ./dists -e ./tools" > md5sum.txt
cat iso_mount/sha256sum.txt | grep -v -e " ./install" -e " ./pool" -e " ./dists -e ./tools" > sha256sum.txt
#new hashes
find new_iso/ -type f -exec bash -c "iso_path=\$(echo {}|sed -e 's|new_iso|\\.|');hash=\$(md5sum {}|cut -d ' ' -f 1);sed -i md5sum.txt -e 's|.* '\$iso_path'|'\$hash'  '\$iso_path'|';echo \$hash \$iso_path" \;
find new_iso/ -type f -exec bash -c "iso_path=\$(echo {}|sed -e 's|new_iso|\\.|');hash=\$(sha256sum {}|cut -d ' ' -f 1);sed -i sha256sum.txt -e 's|.* '\$iso_path'|'\$hash'  '\$iso_path'|';echo \$hash \$iso_path" \;
mv md5sum.txt new_iso/
mv sha256sum.txt new_iso/

if [ $debug -eq 1 ]; then
  read -p "debug pause"
fi

sudo umount new_root/dev
sudo umount new_root/var/cache/apt
sudo umount new_root
sudo umount root_mount
sudo umount iso_mount
sudo umount * 2>/dev/null

if [ $debug -eq 1 ]; then
  read -p "debug pause"
fi

xorriso -boot_image any keep -indev "$ISO_FILE" -outdev cursed.iso  -map new_iso / -rm_r /install /dists /pool /firmware /pool-udeb /tools  
#-rm_r /boot/grub/x86_64-efi

if [ $debug -eq 1 ]; then
  read -p "debug pause"
fi

cd -
new_iso_name=cursed-$(date "+%Y%m%d%H%M%S")-`sha256sum /tmp/cursed_dvd/cursed.iso | cut -d " " -f 1`.iso
mv /tmp/cursed_dvd/cursed.iso $new_iso_name

if [ $test_boot -ne 0 ]; then
  qemu-system-x86_64 -cdrom $new_iso_name -bios /usr/share/qemu/OVMF.fd -m 8192 -smp 8 --enable-kvm
fi
