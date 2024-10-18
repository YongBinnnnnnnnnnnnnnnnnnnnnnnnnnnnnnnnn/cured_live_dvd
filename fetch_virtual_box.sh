#!/bin/bash
mkdir download
cd download
curl -L -O -C - `curl -s https://www.virtualbox.org/wiki/Linux_Downloads|grep "Debian.*\.deb" -m 1| sed -r -e 's|.*href="([^"]*)".*|\1|'`
curl -L -O -C - `curl -s https://www.virtualbox.org/wiki/Downloads|grep "\.vbox-extpack" -m 1| sed -r -e 's|.*href="([^"]*)".*|\1|'`
curl -L -o virtualbox_sha256sums -C - https://www.virtualbox.org/`curl -s https://www.virtualbox.org/wiki/Downloads|grep "/SHA256SUMS" -m 1| sed -r -e 's|.*href="([^"]*)".*|\1|'`

