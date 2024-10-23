#!/bin/bash
# Bin Yong all rights reserved.

if realpath /proc/$PPID/exe | grep /usr/sbin/NetworkManager; then
  sleep 60
  exit 0
fi

if /lib/cursed/sbin/dhclient "$@"; then
  sudo killall dhclient 
  echo "dhclient killed."
fi
