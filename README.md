# AlpineWSL-OOBE
![Alpine Linux](alpinelinux-logo.png)


## What's this?
Enhance your alpine experience, for WSL users.

## Get started
Install alpine with [this](https://apps.microsoft.com/detail/9P804CRF0395) helper application.\
Execute ```oobe.sh``` or setup manually.

## OOBE explained
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

# Enable OpenRC on WSL
cat <<ORC > /etc/wsl.conf
[boot]
command = "/sbin/openrc sysinit && /sbin/openrc boot && /sbin/openrc default"
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
- Since OpenRC functional, we can use docker for further development now:
  ```
  apk add docker docker-cli-compose
  rc-update add docker default
  ```
  > [!NOTE]
  > If daemon failed to startup with system, try this:
  > ```
  > cat <<ENI > /etc/network/interfaces
  > auto lo
  > iface lo inet loopback
  > iface lo inet6 loopback
  > ENI
  > ```

## Mass-Storage and UVCVideo support
> [!NOTE]
> Unavailiable for 6.6 Kernel, exploring workrounds
> See [this issue](https://github.com/microsoft/WSL/issues/11738) for more info.
>
The WSL kernel has builtin USB/IP support but no actually USB drivers provided by default, so let's do this.
You can run ```kernel.sh``` to automatically build a kernel.
> [!NOTE]
> If you see errors like 
> ```
> . : File C:\Users\HarukaX\Documents\WindowsPowerShell\profile.ps1 cannot be loaded because running scripts is disabled
> ``` 
> Please enable it in Developer Settings > PowerShell section.
### Prepare
Make sure you have ```/mnt/c/``` in your alpine WSL, if it doesn't, simply start a PowerShell window and then type  ```bash``` to mount the C: volume, or ```wsl``` if you didn't install bash.
> [!NOTE]
> The ```sh``` will drop you into a Windows sh environment, not the WSL one.
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


# Credits
- [wsl2_linux_kernel_usbcam_enable_conf](https://github.com/PINTO0309/wsl2_linux_kernel_usbcam_enable_conf): Provide instructions to build a custom WSL kernel.
- [WSL2でUSBデバイスを扱えるようになっていました](https://qiita.com/ryoma-jp/items/9db6cca5ed10f1aed7ff): Find the ```make menuconfig``` entry to enable uvcvideo support.