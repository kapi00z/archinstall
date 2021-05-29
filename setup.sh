#!/bin/bash

echo "Provide host number: "
read host

hostnamectl set-hostname="arch${host}"
sed -i "s/arch/arch${host}/g" /etc/hosts

if [[ ! $(sudo cat /etc/dhcpcd.conf | grep -e "static " | wc -l) -eq "0" ]]
then
    echo "Static IP already!"
    export addr=$(cat /etc/dhcpcd.conf | grep -e "ip_address" | sed 's/[\/]/./' | cut -d "." -f 4)
    if [[ "$addr" == "3${host}" ]]
    then
        echo "Static IP address correct!"
    else
        sed -i "s/${addr}/3${host}/" /etc/dhcpcd.conf
    fi
else
    cat << EOF >> /etc/dhcpcd.conf

interface enp0s3
static ip_address=192.168.1.3${host}/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1 8.8.4.4
EOF
fi

pacman -S sudo vim python openssh --noconfirm

sed 's/# %wheel ALL=(ALL) NOPASSWD: ALL/ %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
useradd -aG wheel kacper
echo "Provide password: "
read pass
echo "kacper:${pass}" | chpasswd

systemctl restart dhcpcd
ip addr flush enp0s3
systemctl enable sshd
systemctl start sshd
