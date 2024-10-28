#!/bin/bash
# Bin Yong all rights reserved.

if realpath /proc/$PPID/exe | grep /usr/sbin/NetworkManager; then
  sleep infinity
  # todo detect addr change
  exit 0
fi

if /lib/cured/sbin/dhclient "$@"; then
  sudo killall dhclient 
  echo "dhclient killed."
fi
