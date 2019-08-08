#!/bin/bash
# 
# This script is intended for auto building the chrooted environment
# by prepopulating the base system with packages intended for installation
#
#

# CONSTANTS
PACKAGE_PATH="/root"

# HELPER FUNCTION
function cEcho(){
    local exp=$1;
    local color="green";
    if ! [[ $color =~ '^[0-9]$' ]] ; then
       case $(echo $color | tr '[:upper:]' '[:lower:]') in
        black) color=0 ;;
        red) color=1 ;;
        green) color=2 ;;
        yellow) color=3 ;;
        blue) color=4 ;;
        magenta) color=5 ;;
        cyan) color=6 ;;
        white|*) color=7 ;; # white or invalid color
       esac
    fi
    tput setaf $color;
    echo $exp;
    tput sgr0;
}



### PREPARATION STEP

cEcho "[-] Preparing chrooted environment"
mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts

export HOME=/root
export LC_ALL=C

# Set global locale
echo "LL_ALL=\"C.UTF-8\"" >> /etc/default/locale

# Set Swappiness
echo "vm.swappiness=10" >> /etc/sysctl.conf

# Allow huge pages
echo "vm.nr_hugepages=128" >> /etc/sysctl.conf

# Kernel panic
echo "kernel.panic=20" >> /etc/sysctl.conf


cEcho "[-] Preparing for installation"
dbus-uuidgen > /var/lib/dbus/machine-id
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

#cEcho "[-] Adding china mirror"
#echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main" >> /etc/apt/sources.list
#echo "deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main" >> /etc/apt/sources.list
#DEBIAN_FRONTEND=noninteractive /usr/bin/apt -q 2 -y update

# Install base file, this can be performed via seed file!
cEcho "[-] Installing base files"
DEBIAN_FRONTEND=noninteractive /usr/bin/apt -q 2 -y install openssh-server build-essential software-properties-common dkms

# Enable extra repositories
cEcho "[-] Adding universe, multivers and restricted repositories"
/usr/bin/apt-add-repository -n universe
/usr/bin/apt-add-repository -n multiverse
/usr/bin/apt-add-repository -n restricted

# Apt Fast repository
cEcho "[-] Adding apt fast repository"
/usr/bin/apt-add-repository -s -n -y ppa:apt-fast/stable

# Add Awesome WM custom repo
cEcho "[-] Adding Awesome wm repository"
/usr/bin/add-apt-repository -s -n -y ppa:klaus-vormweg/awesome

# Cuda repository for nvidia
cEcho "[-] Adding Nvidia repository"
/usr/bin/apt-add-repository -s -n -y ppa:graphics-drivers/ppa
/usr/bin/dpkg -i $PACKAGE_PATH/deb/nvidia/*
/usr/bin/apt-key add $PACKAGE_PATH/keys/7fa2af80.pub

# Repopulate the database
cEcho "[-] Refreshing apt repository database"
DEBIAN_FRONTEND=noninteractive /usr/bin/apt -q 2 -y update

# Install apt fast for faster download
cEcho "[-] Installing apt fast"
DEBIAN_FRONTEND=noninteractive /usr/bin/apt install -q 2 -y apt-fast -o Dpkg::Options::="--force-confdef"

# Install all the required program that can be installed via ubuntu repository
cEcho "[-] Installing softwares"
DEBIAN_FRONTEND=noninteractive /usr/bin/apt install -q 2 -y \
	ubuntu-standard casper lupin-casper discover laptop-detect os-prober linux-generic \
	grub2 plymouth-x11 network-manager \
	nvidia-driver-418 nvidia-cuda-toolkit nvidia-settings lightdm- cuda-cudart-9-2 \
	python python-pip  python-nfqueue  python-urwid  python-setuptools  \
	python-ptyprocess  python-lzma  python-minimal  python-magic  python-soappy \
	python-wstools  python-wheel  python-dev  python-pkg-resources  python-pip-whl  libsystemd-dev \
	libcurl4 curl libmicrohttpd12 libssl1.0.0 gir1.2-gdkpixbuf-2.0 libgdk-pixbuf2.0-0 libgdk-pixbuf2.0-0 libgdk-pixbuf2.0-common \
	lm-sensors wget nodm xinit awesome \
	kio xdg-utils kde-cli-tools trash-cli libglib2.0-bin gvfs-bin gconf-service-backend \
	gconf2-common libgconf-2-4 libdbus-glib-1-2 gconf-service libgconf2-4 libnotify4 xterm net-tools \
	-o Dpkg::Options::="--force-confdef"


# Installing amd headless driver
# Need to trick the driver to think that we are on 18.04.
# remove the trick when the driver got updated
cEcho "[-] Installing AMD driver"

sed -i 's/VERSION_ID="18.10"/VERSION_ID="18.04"/g' /etc/os-release
$PACKAGE_PATH/deb/amd/amdgpu-pro-install -y --opencl=pal,legacy --headless
sed -i 's/VERSION_ID="18.04"/VERSION_ID="18.10"/g' /etc/os-release


### INSTALLING SOFTWARE

# Installing python dependencies from pip and locally saved file
cEcho "[-] Installing Python requirements"
/usr/bin/pip install $PACKAGE_PATH/pip/*

# Websocket problematic need to install it last
/usr/bin/pip uninstall -y websocket-client
/usr/bin/pip install websocket-client

# Installing packages
cEcho "[-] Installing miners and tools"
DEBIAN_FRONTEND=noninteractive /usr/bin/dpkg -i --force-confdef $PACKAGE_PATH/deb/packages/*


### FINALIZING INSTALLATION

# Attempt to configure xserver, this probably wont work since we dont have proper GPU initialized yet
# This should be done manually by user after the system boots
cEcho "[-] Configuring XServer"
cp -f $PACKAGE_PATH/files/edid.bin /etc/X11
cp -f $PACKAGE_PATH/files/10-monitor.conf /usr/share/X11/xorg.conf.d/
cp -f $PACKAGE_PATH/files/10-nvidia.conf /usr/share/X11/xorg.conf.d/


# AMDGPU setup
cEcho "[-] Configuring AMD driver"
echo "export LLVM_BIN=/opt/amdgpu-pro/bin" || tee /etc/profile.d/amdgpu-pro.sh

cEcho "[-] Disable motd"
sed -i 's/^ENABLED=.*/ENABLED=0/' /etc/default/motd-news
rm -rf /etc/update-motd.d/*


cEcho "[-] Removing ubuntu branding"
echo "JXOS \n \l" > /etc/issue
echo "JXOS" > /etc/issue.net


# Configuring nodm
cEcho "[-] Configuring NoDM"
sed -i 's|NODM_ENABLED=false|NODM_ENABLED=true|g' /etc/default/nodm
sed -i 's|NODM_USER=root|NODM_USER=jxminer|g' /etc/default/nodm
cp -r /etc/default/nodm /etc/nodm.conf


# Adding jxos user
cEcho "[-] Generating default user"
useradd jxminer
echo -e "jxminer\njxminer" | passwd jxminer

cEcho "[-] Changing root password"
echo -e "jxminer\njxminer" | passwd


cEcho "[-] Configuring Awesome"
mkdir -p /home/jxminer/.config/awesome
mkdir -p /etc/xdg/awesome

cp -rf $PACKAGE_PATH/files/rc.lua /etc/xdg/awesome/rc.lua
cp -rf $PACKAGE_PATH/files/rc.lua /home/jxminer/.config/awesome/rc.lua

cEcho "[-] Configuring JXMiner"
mkdir -p /home/jxminer/.jxminer
cp -rf $PACKAGE_PATH/jxminer/* /home/jxminer/.jxminer

cEcho "[-] Setting bash as the default shell for jxminer"
chsh -s /bin/bash jxminer
usermod -aG sudo jxminer

cEcho "[-] Preparing setup files"
mkdir -p /home/jxminer/setup/files
mv /root/files/jxos-setup.service /etc/systemd/system/
mv /root/scripts/* /home/jxminer/setup/
mv /lib/udev/rules.d/71-nvidia.rules /home/jxminer/setup/files/
mv /lib/systemd/system/nvidia-persistenced.service /home/jxminer/setup/files/

cEcho "[-] Updating locales"
echo "export LANGUAGE=C.UTF-8" >> /home/jxminer/.bash_profile
echo "export LANG=C.UTF-8" >> /home/jxminer/.bash_profile
echo "export LC_ALL=C.UTF-8" >> /home/jxminer/.bash_profile
echo "LANGUAGE=C.UTF-8" >> /etc/environment
echo "LANG=C.UTF-8" >> /etc/environment
echo "LC_ALL=C.UTF-8" >> /etc/environment

cEcho "[-] Fixing jxminer home folders"
chown -R jxminer:jxminer /home/jxminer
usermod -m -d /home/jxminer jxminer

cEcho "[-] Disabling motd at pam.d"
sed -i 's|session    optional     pam_motd.so  motd=/run/motd.dynamic|# session    optional     pam_motd.so  motd=/run/motd.dynamic|g' /etc/pam.d/sshd
sed -i 's|session    optional     pam_motd.so noupdate|# session    optional     pam_motd.so noupdate|g' /etc/pam.d/sshd


systemctl daemon-reload

cEcho "[-] Setting up systemctl"
systemctl enable jxminer
systemctl enable nodm
systemctl enable jxos-setup

systemctl disable ufw
systemctl disable apt-daily-upgrade
systemctl disable apt-daily
systemctl disable ModemManager
systemctl disable pppd-dns
systemctl disable apport-forward
systemctl disable apport
systemctl disable unattended-upgrades
systemctl disable wpa_supplicant
systemctl disable apparmor
systemctl disable snapd.hold
systemctl disable accounts-daemon
systemctl disable apport-autoreport
systemctl disable nvidia-persistenced
systemctl disable lxd-containers
systemctl disable lvm2-lvmetad
systemctl disable motd-news

rm -f /etc/systemd/system/apparmor.service
rm -f /etc/systemd/system/apport-forward.socket
rm -f /etc/systemd/system/ufw.service
rm -f /etc/systemd/system/timers.target.wants/apt-daily-upgrade.timer
rm -f /etc/systemd/system/timers.target.wants/apt-daily.timer
rm -f /etc/systemd/system/sockets.target.wants/apport-forward.socket
rm -f /etc/systemd/system/lvm2*
rm -f /etc/systemd/system/lxd*
rm -f /etc/systemd/system/pppd-dns.service
rm -f /etc/systemd/system/snapd*
rm -f /etc/systemd/system/unattended-upgrades.service
rm -f /etc/systemd/system/timers.target.wants/motd-news.timer
rm -f /lib/systemd/system/apt-daily*
rm -f /lib/systemd/system/avahi*
rm -f /lib/systemd/system/bluetooth*
rm -f /lib/systemd/system/motd*

cEcho "[-] Removing packages"
DEBIAN_FRONTEND=noninteractive /usr/bin/apt -q 2 -y purge \
   apparmor ufw apport plymouth* update-manager-core accountsservice \
   ftp modemmanager ppp popularity-contest unattended-upgrades \
   vlc* lvm2 lxd ubuntu-release-upgrader-core tmux vim screen lxd-client squashfs-tools pinentry-curses \
   fakeroot desktop-file-utils



cEcho "[-] Generating manifest"
dpkg-query -W --showformat='${Package} ${Version}\n' > $PACKAGE_PATH/filesystem.manifest

# Clean apt cache
cEcho "[-] Cleaning chrooted environment"
DEBIAN_FRONTEND=noninteractive /usr/bin/apt -q 2 -y --force-yes autoremove -o Dpkg::Options::="--force-confdef"
DEBIAN_FRONTEND=noninteractive /usr/bin/apt clean

# Remove installation sources
rm -rf $PACKAGE_PATH/jxminer
rm -rf $PACKAGE_PATH/pip
rm -rf $PACKAGE_PATH/deb
rm -rf $PACKAGE_PATH/keys
rm -rf $PACKAGE_PATH/files
rm -rf /tmp/* ~/.bash_history

# Remove uuid
rm /var/lib/dbus/machine-id
rm /sbin/initctl

dpkg-divert --rename --remove /sbin/initctl


# Unmount and exit
umount -lf /proc
umount -lf /sys
umount -lf /dev/pts


cEcho "[-] Finished processing chrooted, exiting to main shell"
exit
