#!usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -x

echo 'nameserver 8.8.8.8' > /etc/resolv.conf

apt-get update
apt-get -y install locales apt-utils

echo "LANG=en_US.UTF-8" > /etc/default/locale
echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale

mount -t proc proc proc/
mount -t sysfs sys sys/

export DEBIAN_FRONTEND="noninteractive"
locale-gen "en_US.UTF-8"
dpkg-reconfigure locales

echo -n 'libre-computer-board' > /etc/hostname
sed -i '1 a 127.0.1.1	libre-computer-board' /etc/hosts
adduser libre --gecos "Libre Computer Board,,," --disabled-password
echo "libre:computer" | chpasswd
echo "root:root" | chpasswd
adduser libre sudo
adduser libre audio
adduser libre dialout
adduser libre video

apt-get -y dist-upgrade
apt-get install -y ubuntu-desktop rng-tools libatomic1

systemctl enable rng-tools

# Disable CPU/RAM-consuming services
apt -y purge gnome-software
mv /usr/lib/evolution-data-server /usr/lib/evolution-data-server-disabled
mv /usr/lib/evolution /usr/lib/evolution-disabled

# Basic network setup
cat > /etc/network/interfaces.d/eth0 <<EOF
allow-hotplug eth0
iface eth0 inet dhcp
EOF
mkdir -p /etc/systemd/system/network-online.target.wants/
ln -snf /lib/systemd/system/networking.service /etc/systemd/system/network-online.target.wants/networking.service

# chromium looks for this specific path for libv4l2
ln -s aarch64-linux-gnu/libv4l2.so.0 /usr/lib/libv4l2.so

# Clean up packages
apt-get -y autoremove
apt-get -y clean
apt-get -y autoclean

# Install mutter packages modified for mali
dpkg -i /root/*.deb

# Install mesa dev packages
apt install -y libgles2-mesa-dev libegl1-mesa-dev libgbm-dev

# Lock chromium/mutter/xwayland package version
apt-mark hold chromium-browser mutter mutter-common gir1.2-mutter-3 libmutter-3* xwayland xserver-xorg-core

# Lock mesa libs packages to avoid reinstalling over mali
apt-mark hold libgles2* libegl1* libgbm1 libwayland-egl1-mesa

umount /proc /sys
