gzip -d -c mobian-pinephonepro-phosh-12.0.img.gz | sed -e "s|ttyS2|wyee0|g" -e "s|load-module module-suspend-on-idle|#oad-module module-suspend-on-idle|g"|sudo dd of=/dev/sdb bs=4M status=progress
