# AlpineWSL-OOBE
![Alpine Linux](alpinelinux-logo.png)


## What's this?
Enhance your alpine experience, for WSL users.

## Get started
Install alpine with [this](https://apps.microsoft.com/detail/9P804CRF0395) helper application.\
Execute ```oobe.sh``` or setup manually.

## Step by step
### Repository
> [!NOTE]
> If you prefer stable release, then replace all ```edge``` with ```latest-stable```, you can skip this section to avoid unexpected release upgrades.
```
cat <<APK > /etc/apk/repositories
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
https://dl-cdn.alpinelinux.org/alpine/edge/testing
APK
apk upgrade -Ua
```
### Some fix
These solutions are useful in most situations, but you are the boos.
```
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
```
> [!NOTE]
> Restart WSL to apply the changes.
### Else
- For some scripts complain about
  ```
  grep: unrecognized option: P
  ```
  Install a full-featured grep by:
  ```
  apk add grep
  ```
  to fix the problem.
- Since OpenRC works, we can use docker for further development:
  ```
  apk add docker docker-cli-compose
  rc-update add docker default
  ```
  > [!NOTE]
  > If daemon failed to startup with system, try this:
  > ```
  > sed -ri 's@#?need sysfs cgroups net@#need sysfs cgroups net@g' /etc/init.d/docker
  > ```

## Mass-Storage and UVCVideo support
The WSL kernel has builtin USB/IP support but no actually USB drivers provided by default, so let's do this.
### Prepare
Make sure you have /mnt/c/ in your alpine WSL, if it doesn't, simply start a PowerShell window and then type  ```bash``` to mount the C: volume, or ```wsl``` if you didn't install bash.
> [!NOTE]
> The ```sh``` will drop you into a Windows sh environment, not the WSL one.
Plus, we don't have to specify a USERNAME variable, instead we call ```powershell.exe``` directly and a little hacking stuff to get a useable path.
```
cd ~/
TAGVERNUM=$(uname -r | sed -r "s/-.+\+?//g")
TAGVER=linux-msft-wsl-${TAGVERNUM}
WIN_USERPROFILE=$(powershell.exe '$env:USERPROFILE' | sed -r 's#\r##g')
WSL_USERPROFILE=$(wslpath -u "$WIN_USERPROFILE")
```
Then we clone the kernel source and copy the current kernel config
```
rm -rf *-microsoft-standard
git clone --depth 1 -b ${TAGVER} \
    https://github.com/microsoft/WSL2-Linux-Kernel.git \
    ${TAGVERNUM}-microsoft-standard
cd ${TAGVERNUM}-microsoft-standard

cp /proc/config.gz config.gz \
    && gunzip config.gz \
    && mv config .config
```
Create a one-time ubuntu docker
```
docker run -itd --rm --name ub \
    -w /wsl \
    -v "${PWD}:/wsl" \
    ubuntu /bin/bash

docker exec ub apt update
docker exec ub apt install -y build-essential flex bison \
    libgtk-3-dev libelf-dev libncurses-dev autoconf \
    libudev-dev libtool zip unzip v4l-utils libssl-dev \
    python3-pip cmake git iputils-ping net-tools dwarves \
    guvcview python-is-python3 bc
docker exec -it ub make menuconfig
```
### Configure
To enable USB Mass-Storage amd UVCVideo support, go:
```     
    Device Drivers  --->
    <*> Multimedia support  --->
         Media drivers  --->
             [*] Media USB Adapters  --->
                 <*>   USB Video Class (UVC)
    [*] USB support  --->
        <*>   USB Mass Storage support
```
### Build
```
docker exec ub make -j$(nproc) KCONFIG_CONFIG=.config
docker exec ub make modules -j$(nproc) KCONFIG_CONFIG=.config
```
### Insall modules
Now we can terminate the docker
```
docker stop ub
```
Install required packages and kernel modules
```
apk add alpine-sdk
make modules_install -j$(nproc)
```
### Update the kernel
This will update the kernel and the wslconfig file inside %USERPROFILE% at Windows side:
```
rm -f ${WSL_USERPROFILE}/vmlinux
cp ./vmlinux $WSL_USERPROFILE/
cat <<WSL > ${WSL_USERPROFILE}/.wslconfig
[wsl2]
kernel=${WIN_USERPROFILE}\vmlinux
WSL
sed -i 's#\\#\\\\#g' ${WSL_USERPROFILE}/.wslconfig
wsl.exe --shutdown
```
> [!NOTE]
> if you modified ```.wslconfig``` previously, make sure to make a backup and skip this section, then edit the file manually.


# Credits
- [wsl2_linux_kernel_usbcam_enable_conf](https://github.com/PINTO0309/wsl2_linux_kernel_usbcam_enable_conf): Provide instructions to build a custom WSL kernel.
- [WSL2でUSBデバイスを扱えるようになっていました](https://qiita.com/ryoma-jp/items/9db6cca5ed10f1aed7ff): Find the ```make menuconfig``` entry to enable uvcvideo support.