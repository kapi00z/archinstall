#!/bin/bash

getHost() {
    read -p "Please provide hostname: " host
    echo $host
}

getIP() {
    read -p "Please provide IP address: 192.168.1." addr
    echo $addr
}

getUser() {
    read -p "Please provide username [kacper]: " user
    if [[ $user == "" ]]
    then
        user="kacper"
    fi
    echo $user
}

getUserPass() {
    user="$1"
    if [[ "$user" == "kacpi" ]]
    then
        defpass="kacper"
    else
        defpass="$user"
    fi
    read -p "Please provide password for $user [$defpass]: " pass
    if [[ $pass == "" ]]
    then
        pass="$defpass"
    fi
    echo $pass
}

showDisk() {
    echo "Available disks:"
    fdisk -l | grep -ie 'disk /dev/' | sed '/loop/d' | awk '{print $2 ": " $3"GB"}' | sed 's/\:\|\,//g'
    res=(`lsblk | grep -ie 'disk' | awk '{print "/dev/" $1}'`)
    if [[ ${res[@]} =~ 'sda' ]]
    then
        def='/dev/sda'
    else
        def="${res[0]}"
    fi
    echo; echo -n "Select disk to install [$def]: "
}

getDisk() {
    res=(`lsblk | grep -ie 'disk' | awk '{print "/dev/" $1}'`)
    read disk
    if [[ "$disk" == "" ]]
    then
        disk="$def"
    elif [[ ! ${res[@]} =~ $( echo "$disk" | sed 's/\/dev\///g') ]]
    then
        echo "$disk not detected, ending!"
        exit 0
    fi
    echo $disk
}

autoPart() {
    #disk="$1"
    echo "$disk"
    cat << EOF | fdisk $disk
g
n


+512M
n



t
1
1
w
EOF

    mkfs.vfat ${disk}1
    mkfs.ext4 ${disk}2

    mount ${disk}2 /mnt
    mkdir /mnt/boot
    mount ${disk}1 /mnt/boot
}

install() {
    pacstrap /mnt base linux linux-firmware dhcpcd grub efibootmgr vim sudo python openssh

    genfstab -U /mnt >> /mnt/etc/fstab

    echo "${host}" > /mnt/etc/hostname

    hostnamectl set-hostname "${host}"

    sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen

    arch-chroot /mnt timedatectl set-timezone Europe/Warsaw
    arch-chroot /mnt timedatectl set-ntp true
    arch-chroot /mnt hwclock --systohc

    arch-chroot /mnt systemctl enable dhcpcd
    arch-chroot /mnt systemctl enable sshd
}

setup() {
    url='https://raw.githubusercontent.com/kapi00z/archinstall/master/vmware/setup.sh'

    curl ${url} > /mnt/root/setup.sh

    arch-chroot /mnt bash /root/setup.sh $host $addr $user $pass
}

grub() {
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

args=($@)

if [[ $(echo ${args[@]} | grep -ie '-h\|-a\|-d\|-u\|-p\|-k' ) ]]
then
    if [[ $(echo ${args[@]} | awk '/-a/ && /-h/' ) ]]
    then
        while getopts ":a:d:h:u:p:k" opt; do
            case $opt in
                a)
                    addr="192.168.1.${OPTARG}"
                    ;;
                d)
                    disk="${OPTARG}"
                    ;;
                h)
                    host="${OPTARG}"
                    ;;
                p)
                    pass="${OPTARG}"
                    ;;
                u)
                    user="${OPTARG}"
                    ;;
                k)
                    defuser="true"
                    ;;
                *)
                    echo "-h -- hostname"
                    echo "-a -- IP address ending (192.168.1.<a>)"
                    echo "-d -- disk"
                    echo "-u -- username"
                    echo "-p -- password"
                    echo "-k -- create kacper (kacper:kacpi), overrides -u and -p"
                    ;;
            esac
        done
        if [[ ! $(echo ${args[@]} | grep -ie '-d' ) ]] || [[ "$disk" == "" ]]
        then
            showDisk
            disk=$(getDisk)
        fi
        if [[ "$defuser" == "true" ]]
        then
            user="kacper"
            pass="kacpi"
        else
            if [[ ! $(echo ${args[@]} | grep -ie '-u' ) ]]
            then
                user=$(getUser)
                pass=$(getUserPass $user)
            elif [[ ! $(echo ${args[@]} | grep -ie '-p' ) ]]
            then
                pass="$user"
            fi
        fi
    else
        echo "both host and IP needed!"
        exit 0
    fi
else
    host=$(getHost)
    addr="192.168.1.$(getIP)"
    user=$(getUser)
    pass=$(getUserPass $user)
    showDisk
    disk=$(getDisk)
fi

echo "$host $addr $user $pass $disk"

timedatectl set-ntp true

for var in $host $addr
do
    if [[ $var == "" ]]
    then
        echo "Empty variable provided!"
        exit 0
    fi
done

#define partitions, format & mount
autoPart

#install arch
install
grub

setup