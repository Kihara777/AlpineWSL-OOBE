#!/bin/sh

WKB="WslKernelBuilder"

cd ~/
echo "[Builder]    Current kernel:"
TAGVERNUM=$(uname -r | sed -r "s/-.+\+?//g")
TAGVER=linux-msft-wsl-${TAGVERNUM}
WIN_USERPROFILE=$(powershell.exe '$env:USERPROFILE' | sed -r 's#\r##g')
WSL_USERPROFILE=$(wslpath -u "$WIN_USERPROFILE")
echo "[Builder]    ${TAGVERNUM}-microsoft-standard"

if [ ! -d "${TAGVERNUM}-microsoft-standard" ]; then
    echo "[Builder]    Download kernel source..."
    git clone --depth 1 -b ${TAGVER} \
        https://github.com/microsoft/WSL2-Linux-Kernel.git \
        ${TAGVERNUM}-microsoft-standard
fi
cd ${TAGVERNUM}-microsoft-standard

if [ ! -f ".config" ]; then
    echo "[Builder]    Restore kernel configuration..."
    cp /proc/config.gz config.gz \
        && gunzip config.gz \
        && mv config .config
    echo "[Builder]    Add UVC settings..."
    sed -ri 's/^# CONFIG_MEDIA_USB_SUPPORT=y/CONFIG_MEDIA_USB_SUPPORT=y/' .config
    sed -ri 's/^# CONFIG_USB_VIDEO_CLASS=y/CONFIG_USB_VIDEO_CLASS=y/' .config
    sed -ri 's/^# CONFIG_USB_VIDEO_CLASS_INPUT_EVDEV=y/CONFIG_USB_VIDEO_CLASS_INPUT_EVDEV=y/' .config
    sed -ri 's/^# CONFIG_USB_STORAGE=y/CONFIG_USB_STORAGE=y/' .config
fi

echo "[Builder]    Run Builder..."
if ! docker ps -a | grep -q "$WKB"; then
    docker run -itd --name $WKB \
        -w /wsl \
        -v "${PWD}:/wsl" \
        -e "DEBIAN_FRONTEND=noninteractive" \
        ubuntu /bin/bash

    docker exec $WKB apt update
    docker exec $WKB apt install -yq build-essential flex bison \
    libgtk-3-dev libelf-dev libncurses-dev autoconf \
    libudev-dev libtool zip unzip v4l-utils libssl-dev \
    python3-pip cmake git iputils-ping net-tools dwarves \
    guvcview python-is-python3 bc

fi
if [ "$@" = "menu" ]; then
    echo "[Builder]    Enter kernel config menu..."
    docker exec -it ub make menuconfig
fi
echo "[Builder]    Start build kernel..."
docker exec $WKB make -j$(nproc) KCONFIG_CONFIG=.config && \
    docker stop $WKB > /dev/null

echo "[Builder]    Install new kernel..."
rm -f ${WSL_USERPROFILE}/vmlinux
cp ./vmlinux $WSL_USERPROFILE/
cat <<WSL > ${WSL_USERPROFILE}/.wslconfig
[wsl2]
kernel=${WIN_USERPROFILE}\vmlinux
WSL
sed -i 's#\\#\\\\#g' ${WSL_USERPROFILE}/.wslconfig

wsl.exe --shutdown