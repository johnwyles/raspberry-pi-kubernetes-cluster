#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

if [ -z ${1} ]; then
  echo "Usage: ./make-rpi.sh <wifi-ssid> <wifi-password> <router-ip-address> <image-filename> <usb--disk-device-path> <hostname> <ip-address>"
  echo "       ./make-rpi.sh WiFi-5g password 192.168.1.1 2018-11-13-raspbian-stretch-lite.img /dev/sda node-1 192.168.1.101"
  echo "       ./make-rpi.sh WiFi-5g password 192.168.1.1 2018-11-13-raspbian-stretch-lite.img /dev/sda node-2 192.168.1.102"
  exit 1
fi

echo "Writing Raspbian Lite image to SD card"
time dd if=${4} of=/${5} bs=1M

sync

echo "Mounting SD card from ${5}..."

sudo mkdir -p /mnt/rpi/boot
sudo mkdir -p /mnt/rpi/root

sudo umount /dev/${5}2

mount ${5}1 /mnt/rpi/boot
mount ${5}2 /mnt/rpi/root

# Add our SSH key
mkdir -p /mnt/rpi/root/home/pi/.ssh/
chmod 700 /mnt/rpi/root/home/pi/.ssh
cp template-authorized_keys /mnt/rpi/root/home/pi/.ssh/authorized_keys
chmod 600 /mnt/rpi/root/home/pi/.ssh/authorized_keys

# Enable ssh
touch /mnt/rpi/boot/ssh

# Disable password login
sed -ie s/#PasswordAuthentication\ yes/PasswordAuthentication\ no/g /mnt/rpi/root/etc/ssh/sshd_config

echo "Setting hostname: ${6}"
sed -e "s/raspberrypi/${6}/g" -i /mnt/rpi/root/etc/hostname
sed -e "s/raspberrypi/${6}/g" -i /mnt/rpi/root/etc/hosts

# Set WIFI and static IP
cp template-wpa_supplicant.conf /mnt/rpi/root/etc/wpa_supplicant/wpa_supplicant.conf
sed -e "s/WIFI_SSID/${1}/g" -e "s/WIFI_PASSWORD/${2}/g" -i /mnt/rpi/root/etc/wpa_supplicant/wpa_supplicant.conf

sed -e "s/ROUTER_IP_ADDRESS/${3}/g" -e "s/STATIC_IP_ADDRESS/${7}/g" -i /mnt/rpi/root/etc/dhcpcd.conf

echo "Unmounting SD Card..."

umount /mnt/rpi/boot
umount /mnt/rpi/root

sync
