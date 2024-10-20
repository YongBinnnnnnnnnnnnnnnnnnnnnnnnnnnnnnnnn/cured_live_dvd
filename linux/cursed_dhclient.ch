#!/bin/bash
# Bin Yong all rights reserved.

if realpath /proc/$PPID/exe | /usr/sbin/NetworkManager; then
  sleep 60
  exit 0
fi

/lib/cursed/sbin/dhclient "$@"
