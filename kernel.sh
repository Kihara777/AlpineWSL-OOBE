#!/bin/sh

# Prepare
cd ~/
TAGVERNUM=$(uname -r | sed -r "s/-.+\+?//g")
TAGVER=linux-msft-wsl-${TAGVERNUM}
WIN_USERPROFILE=$(powershell.exe '$env:USERPROFILE' | sed -r 's#\r##g')
WSL_USERPROFILE=$(wslpath -u "$WIN_USERPROFILE")

rm -rf *-microsoft-standard
git clone --depth 1 -b ${TAGVER} \
    https://github.com/microsoft/WSL2-Linux-Kernel.git \
    ${TAGVERNUM}-microsoft-standard
cd ${TAGVERNUM}-microsoft-standard

cp /proc/config.gz config.gz \
    && gunzip config.gz \
    && mv config .config

docker run -itd --rm --name ub \
    -w /wsl \
    -v "${PWD}:/wsl" \
    -e "DEBIAN_FRONTEND=noninteractive" \
    ubuntu /bin/bash

docker exec ub apt update
docker exec ub apt install -yq build-essential flex bison \
    libgtk-3-dev libelf-dev libncurses-dev autoconf \
    libudev-dev libtool zip unzip v4l-utils libssl-dev \
    python3-pip cmake git iputils-ping net-tools dwarves \
    guvcview python-is-python3 bc

# Configure
sed -ri 's/^# CONFIG_MEDIA_USB_SUPPORT=y/CONFIG_MEDIA_USB_SUPPORT=y/' .config
sed -ri 's/^# CONFIG_USB_VIDEO_CLASS=y/CONFIG_USB_VIDEO_CLASS=y/' .config
sed -ri 's/^# CONFIG_USB_VIDEO_CLASS_INPUT_EVDEV=y/CONFIG_USB_VIDEO_CLASS_INPUT_EVDEV=y/' .config
sed -ri 's/^# CONFIG_USB_STORAGE=y/CONFIG_USB_STORAGE=y/' .config

# Build and install
docker exec ub make -j$(nproc) KCONFIG_CONFIG=.config && \
    docker stop ub > /dev/null

rm -f ${WSL_USERPROFILE}/vmlinux
cp ./vmlinux $WSL_USERPROFILE/
cat <<WSL > ${WSL_USERPROFILE}/.wslconfig
[wsl2]
kernel=${WIN_USERPROFILE}\vmlinux
WSL
sed -i 's#\\#\\\\#g' ${WSL_USERPROFILE}/.wslconfig

wsl.exe --shutdown