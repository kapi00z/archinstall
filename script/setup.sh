#!/bin/bash

hostname="$1"
addr="$2"
user="$3"
pass="$4"

sed -i "s/$(cat /etc/hostname)/${hostname}/g" /etc/hosts
hostnamectl set-hostname "${hostname}"

if [ "$addr" != "n" ]
then
    cat << EOF >> /etc/dhcpcd.conf

interface enp0s3
static ip_address=192.168.1.${addr}/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1 8.8.4.4
EOF
fi

pacman -S sudo vim python openssh --noconfirm

#sed -i 's/# %wheel ALL=(ALL) NOPASSWD: ALL/ %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
#useradd -mG wheel ${user}
useradd -m ${user}
echo "${user} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${user}
echo "${user}:${pass}" | chpasswd

systemctl enable sshd