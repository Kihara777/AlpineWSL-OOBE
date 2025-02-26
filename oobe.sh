#!/bin/sh

# Repo
cat <<APK > /etc/apk/repositories
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
https://dl-cdn.alpinelinux.org/alpine/edge/testing
APK
apk upgrade -Ua

# Fix "clear" in WindowsTerminal
apk add ncurses

# Fix "bash" in Windows side
apk add bash shadow
chsh -s /bin/bash

# VSCode Server runtime
apk add libstdc++

# Enable OpenRC on WSL
cat <<ORC > /etc/wsl.conf
[boot]
command = "/sbin/openrc sysinit && /sbin/openrc boot && /sbin/openrc default"
ORC

# Common shell script requirements
apk add curl grep

# Install Docker
apk add docker docker-cli-compose
rc-update add docker default
# Fix networking service, required by docker
cat <<ENI > /etc/network/interfaces
auto lo
iface lo inet loopback
iface lo inet6 loopback
ENI

# Utilities
# bind-tools: Want nslookup and dig? Do it.
# util-linux-misc: Need whereis whereis? That's it.
# coreutils: Progressive dd?
apk add ffmpeg mpv bind-tools nmap lsblk util-linux-misc

# Development
apk add vim git apptainer alpine-sdk
# Apptainer might mount this, so uncomment it or setup-timezone instead.
#ln -s /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

sync
# Because reboot requires a reboot to take effect, haha.
wsl.exe --shutdown
