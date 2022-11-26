#!/bin/bash

partitioning () {
    cat << EOF > part
g
n


+512M
EOF

    if [ "${home}" == "y" ] && [ "${home_size}" != "" ]
    then
        echo $home
        cat << EOF >> part
n


+${home_size}G
EOF
    fi

    cat << EOF >> part
n



t
1
1
w
EOF

    echo "$(cat part)" | sudo fdisk ${disk}
}

format_and_mount () {
    mkfs.vfat ${disk}1
    mkfs.ext4 ${disk}2

    if [ "${home}" == "y" ]
    then
        mkfs.ext4 ${disk}3
    fi

    if [ "${home}" == "y" ]
    then
        mount ${disk}3 /mnt
        mkdir /mnt/home
        mount ${disk}2 /mnt/home
    else
        mount ${disk}2 /mnt
    fi

    mkdir /mnt/boot
    mount ${disk}1 /mnt/boot
}

after_install () {
    echo "${hostname}" > /mnt/etc/hostname
    cat << EOF > /mnt/etc/hosts
    127.0.0.1       localhost
    ::1             localhost
    127.0.1.1       ${hostname}.localdomain ${hostname}
EOF

    sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen

    arch-chroot /mnt timedatectl set-timezone Europe/Warsaw
    arch-chroot /mnt timedatectl set-ntp true
    arch-chroot /mnt hwclock --systohc

    arch-chroot /mnt systemctl enable dhcpcd

    echo "${root_pass}" > /mnt/root/pass
    arch-chroot /mnt bash -c 'echo "root:$(cat /root/pass)" | chpasswd'
    rm /mnt/root/pass

    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

main () {
    timedatectl set-ntp true

    partitioning
    format_and_mount

    pacstrap /mnt base linux linux-firmware dhcpcd grub efibootmgr virtualbox-guest-utils
    genfstab -U /mnt >> /mnt/etc/fstab

    after_install

    curl "http://192.168.1.${fileserver}:8080/setup.sh" > /mnt/root/setup.sh

    arch-chroot /mnt bash /root/setup.sh ${hostname} ${addr} ${user} ${pass}
}

#VARIABLES
disk="/dev/sda"
home="n"
hostname="arch"
addr="n"
user="kacper"
pass="kacpi"
root_pass="kacpi"
fileserver="205"

#GET OPTS
while getopts ":d:m:n:a:u:p:s:i:h" opt; do
    case $opt in
        d)
            disk="$OPTARG"
            ;;
        m)
            home_size="$OPTARG"
            home="y"
            ;;
        h)
            echo "-d - disk in /dev/sdX format \
                  -m - if you want home on separate partition, size in GB \
                  -n - hostname \
                  -a - the end of IP Address for static IP \
                  -u - name of primary user (with sudo, nopasswd) \
                  -p - pass of primary user \
                  -s - password for root \
                  -i - the end of IP Address for fileserver"
            exit
            ;;
        n)
            hostname="$OPTARG"
            ;;
        a)
            addr="$OPTARG"
            ;;
        u)
            user="$OPTARG"
            ;;
        p)
            pass="$OPTARG"
            ;;
        s)
            root_pass="$OPTARG"
            ;;
        i)
            fileserver="$OPTARG"
            ;;
        :)
            echo "Option $OPTARG has no argument."
            exit
            ;;
    esac
done

#main function

main