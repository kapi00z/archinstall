#!/bin/bash

argarr=(2 4 6)

if [[ ! "${argarr[@]}" =~ "${argnum}" ]]
then
    echo "Incorrect arguments number!"
    exit 0
fi

while getopts ":h:a:" opt
do
    case "${opt}" in
        h)
            opthost=${OPTARG}
            ;;
        a)
            optaddr=${OPTARG}
            ;;
    esac
done

if [[ "${opthost}" == "" ]]
then
    echo "Enter hostname: "
    read host
else
    host=${opthost}
fi

if [[ "${optaddr}" == "" ]]
then
    echo "Enter address: "
    read addr
else
    addr=${optaddr}
fi

#numhost=$(echo "${host}" | sed 's/[^0-9]//g')

echo "Number: ${addr}"
echo "Name: ${host}"

if [[ "$host" == "" ]]
then
    echo "Empty hostname entered, exiting"
    exit 0
elif [[ "$addr" == "" ]]
then
    echo "Cannot generate address, exiting"
    exit 0
elif [[ "$addr" -lt "31" || "$addr" -gt "255" ]]
then
    echo "Address not in range"
    exit 0
fi

hostnamectl set-hostname "${host}"
sed -i "s/arch/${host}/g" /etc/hosts

if [[ ! $(sudo cat /etc/dhcpcd.conf | grep -e "static " | wc -l) -eq "0" ]]
then
    echo "Static IP already!"
    export curaddr=$(cat /etc/dhcpcd.conf | grep -e "ip_address" | sed 's/[\/]/./' | cut -d "." -f 4)
    if [[ "$curaddr" == "${host}" ]]
    then
        echo "Static IP address correct!"
    else
        sed -i "s/${curaddr}/${addr}/" /etc/dhcpcd.conf
    fi
else
    cat << EOF >> /etc/dhcpcd.conf

interface enp0s3
static ip_address=192.168.1.${addr}/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1 8.8.4.4
EOF
fi

pacman -S sudo vim python openssh --noconfirm

sed -i 's/# %wheel ALL=(ALL) NOPASSWD: ALL/ %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
useradd -mG wheel kacper
echo "Provide password: "
read -s pass
echo "kacper:${pass}" | chpasswd

systemctl restart dhcpcd
ip addr flush enp0s3
systemctl enable sshd
systemctl start sshd
