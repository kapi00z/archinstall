#!/bin/bash

args=($@)
argarr=(4 5 8)

URL_MIRROR='https://raw.githubusercontent.com/kapi00z/archinstall/master/mirror.sh'

testval='0'
while getopts ":h:a:u:p:" opt
do
    if [[ "${OPTARG}" == "-"* && "${#OPTARG}" -eq "2" ]]
    then
        echo "Incorrect parameters!"
        exit 0
    fi
    case "${opt}" in
        h)
            opthost=${OPTARG}
            let "testval++"
            ;;
        a)
            optaddr=${OPTARG}
            let "testval++"
            ;;
        u)
            optuser=${OPTARG}
            let "testval++"
            ;;
        p)
            optpass=${OPTARG}
            let "testval++"
            ;;
    esac
done

if [[ "${#args[*]}" -eq "4" && "${testval}" -eq "2" ]]
then
    host=${opthost}
    addr=${optaddr}
    user="kacper"
    pass="kacpi"
elif [[ "${#args[*]}" -eq "8" && "${testval}" -eq "4" ]]
then
    host=${opthost}
    addr=${optaddr}
    user=${optuser}
    pass=${optpass}
else
    echo "Incorrect arguments!"
    exit 0
fi

if [[ "$host" == "" ]]
then
    echo "Empty hostname entered, exiting"
    exit 0
elif [[ "$addr" == "" ]]
then
    echo "Cannot generate address, exiting"
    exit 0
elif [[ "$addr" -lt "11" || "$addr" -gt "255" ]]
then
    echo "Address not in range"
    exit 0
fi

sed -i "s/$(cat /etc/hostname)/${host}/g" /etc/hosts
hostnamectl set-hostname "${host}"

if [[ ! $(cat /etc/dhcpcd.conf | grep -e "static " | wc -l) -eq "0" ]]
then
    echo "Static IP already!"
    curaddr=$(cat /etc/dhcpcd.conf | grep -e "ip_address" | sed 's/[\/]/./' | cut -d "." -f 4)
    if [[ "$curaddr" == "${addr}" ]]
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
echo "${user}:${pass}" | chpasswd

#ip addr flush enp0s3
systemctl enable sshd

curl ${URL_MIRROR} > /tmp/mirror.sh
chmod +x /tmp/mirror.sh
cp /tmp/mirror.sh /usr/local/bin/update-mirrors
rm /tmp/mirror.sh

cat /etc/pacman.d/mirrorlist > /etc/pacman.d/mirrorlist.bak

update-mirrors

