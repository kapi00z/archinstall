#!/bin/bash

if [[ $(id -u) -ne 0 ]]
then
    echo "Must run as root!"
    exit 1
fi

URL='https://archlinux.org/mirrorlist/?country=PL&country=DE&country=NL&country=GB&protocol=https&use_mirror_status=on'

mkdir /tmp/pacmirror

curl ${URL} > /tmp/pacmirror/mirrors
sed -i 's/#Server/Server/g' /tmp/pacmirror/mirrors
rankmirrors -n 15 -m 2 /tmp/pacmirror/mirrors > /tmp/pacmirror/tmp
cat /tmp/pacmirror/tmp | head -n 6 > /tmp/pacmirror/list
cat /tmp/pacmirror/tmp | tail -n 15 > /tmp/pacmirror/list
cat /tmp/pacmirror/list
cat /etc/pacman.d/mirrorlist > /etc/pacman.d/mirrorlist.backup
cat /tmp/pacmirror/list > /etc/pacman.d/mirrorlist
pacman -Syy --noconfirm
rm -rf /tmp/pacmirror
