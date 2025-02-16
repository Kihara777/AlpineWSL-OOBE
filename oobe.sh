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

# Enable OpenRC init
cat <<ORC > /etc/wsl.conf
[boot]
command = "/sbin/openrc sysinit"
ORC

# Common shell script requirements
apk add curl grep

# Install Docker
apk add docker docker-cli-compose
rc-update add docker default
sed -ri 's@#?need sysfs cgroups net@#need sysfs cgroups net@g' /etc/init.d/docker

# Utilities
apk add neofetch ffmpeg ffplay mpv bind-tools nmap lsblk

# Development
apk add git alpine-sdk

sync
wsl.exe --shutdown
