#!/bin/bash

autoPart() {
    #fdisk -l
    #echo -n "Choose partition: "
    #read disk
    disk='/dev/sda'
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

host=$1
pass=$2

URL_SETUP='https://raw.githubusercontent.com/kapi00z/archinstall/master/setup.sh'

#read -p "Set your hostname: " host
#read -ps "Set your root password: " pass

#disk='/dev/sda'

timedatectl set-ntp true

#echo -n "Do you want automatic(a) or manual(m) disk partitioning and formatting (default is automatic): "
#read part
#
#case $part in
#
    #a)
        #autoPart
        #;;
#        
    #"")
        #autoPart
        #;;
#        
    #m)
        #fdisk -l
        #fdisk
        #;;
#
    #*)
        #echo "Incorrect input, ending script"
        #exit 0
        #;;
#
#esac

autoPart

pacstrap /mnt base linux linux-firmware dhcpcd grub efibootmgr virtualbox-guest-utils-nox

genfstab -U /mnt >> /mnt/etc/fstab

echo "${host}" > /mnt/etc/hostname

cat << EOF > /mnt/etc/hosts
127.0.0.1       localhost
::1             localhost
127.0.1.1       ${host}.localdomain ${host}
EOF

sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen

arch-chroot /mnt timedatectl set-timezone Europe/Warsaw
arch-chroot /mnt timedatectl set-ntp true
arch-chroot /mnt hwclock --systohc

arch-chroot /mnt systemctl enable dhcpcd

#echo "Set your root password: "
#arch-chroot /mnt passwd
echo "${pass}" > /mnt/root/pass
arch-chroot /mnt bash -c 'echo "root:$(cat /root/pass)" | chpasswd'
rm /mnt/root/pass

arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

curl ${URL_SETUP} > /mnt/root/setup.sh
