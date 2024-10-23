cat spi.installer.img | sed -e "s|console=ttyS2,115200n8 earlycon=uart8250,mmio32,0xff1a0000|                                                          |" |sudo dd of=/dev/sdb bs=4M status=progress
