#!/bin/sh

WKB="wsl-kernel-builder"

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

echo "[Builder]    Prepare environment..."
if ! docker images -a | grep -q "$WKB"; then
    echo "[Builder]    Build container..."
    docker run -itd --rm --name ${WKB}-tmp \
        -w /wsl \
        -v "${PWD}:/wsl" \
        -e "DEBIAN_FRONTEND=noninteractive" \
        ubuntu /bin/bash > /dev/null
    docker exec $WKB-tmp apt update
    docker exec $WKB-tmp apt install -yq build-essential flex bison \
    libgtk-3-dev libelf-dev libncurses-dev autoconf \
    libudev-dev libtool zip unzip v4l-utils libssl-dev \
    python3-pip cmake git iputils-ping net-tools dwarves \
    guvcview python-is-python3 bc
    echo "[Builder]    Commit to image..."
    docker commit $WKB-tmp $WKB > /dev/null && docker stop $WKB-tmp > /dev/null
    echo "[Builder]    Run container..."
    docker run -itd --name $WKB \
        -w /wsl \
        -v "${PWD}:/wsl" \
        -e "DEBIAN_FRONTEND=noninteractive" \
        $WKB /bin/bash > /dev/null
elif docker ps -a | grep -q "$WKB"; then
    echo echo "[Builder]    Start container..."
    docker start $WKB > /dev/null
else
    echo "[Builder]    Restore container..."
    docker run -itd --name $WKB \
        -w /wsl \
        -v "${PWD}:/wsl" \
        -e "DEBIAN_FRONTEND=noninteractive" \
        $WKB /bin/bash > /dev/null
fi

if [ "-$@" = "-menu" ]; then
    echo "[Builder]    Enter kernel config menu..."
    docker exec -it $WKB make menuconfig
fi
echo "[Builder]    Start build kernel..."
docker exec $WKB make -j$(nproc) KCONFIG_CONFIG=.config && \
    docker stop $WKB > /dev/null

echo "[Builder]    Install new kernel..."
rm -f ${WSL_USERPROFILE}/vmlinux
cp ./vmlinux "$WSL_USERPROFILE/"
cat <<WSL > "${WSL_USERPROFILE}/.wslconfig"
[wsl2]
kernel="${WIN_USERPROFILE}\vmlinux"
WSL
sed -i 's#\\#\\\\#g' "${WSL_USERPROFILE}/.wslconfig"

wsl.exe --shutdown
