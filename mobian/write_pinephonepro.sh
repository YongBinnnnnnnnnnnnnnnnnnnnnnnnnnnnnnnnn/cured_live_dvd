gzip -d -c mobian-pinephonepro-phosh-12.0.img.gz | sed -e "s|ttyS2|wyee0|g" -e "s|load-module module-suspend-on-idle|#oad-module module-suspend-on-idle|g" -e "s|ExecStart=-/sbin/agetty -o '-p -- \\u' --keep-baud 115200,57600,38400,9600 - \$TERM|ExecStart=-/bin/sleep infinity                                                    |g" -e "s|ExecStart=/usr/sbin/avahi-daemon -s|ExecStart=/bin/sleep infinity      |g" -e "s|ExecStart=!!/lib/systemd/systemd-resolved|ExecStart=/bin/sleep infinity            |g" -e "s|ExecStart=ExecStart=!/usr/sbin/chronyd \$DAEMON_OPTS|ExecStart=/bin/sleep infinity            |g" |sudo dd of=/dev/sdb bs=4M status=progress
