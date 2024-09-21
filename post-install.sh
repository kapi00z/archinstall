#!/bin/bash

$args=($@)

#check if normal user
if [ "$EUID" -eq 0 ]
then
    echo "Please run as normal user!"
    exit -1
fi

#install git and yay
sudo pacman -Sy git base-devel --noconfirm

git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin

makepkg -si -D /tmp/yay-bin --noconfirm
rm -rf /tmp/yay-bin

username='kapi00z'
email='hnerno.o@gmail.com'
git config --global user.name $username
git config --global user.email $email

if [ -f ~/.github ]
then
    key="$(cat ~/.github)"
elif [ ${args[0]} != '' ]
then
    key=${args[0]}
else
    read -p "Provide github key (leave empty to skip)" key
fi

if [ "$key" != "" ]
then
    echo "https://${username}:${key}@github.com" > ~/.git-credentials
else
    echo "Github credentials not set up!"
fi

git config --global credential.helper store



#grab vimrc
git clone https://github.com/kapi00z/vimrc.git /tmp/vimrc

cp -f /tmp/vimrc/.vimrc ~
sudo cp -f /tmp/vimrc/.vimrc /root

rm -rf /tmp/vimrc


#install docker
if [ "$(pacman -Qq docker docker-compose; echo $?)" -ne "0" ]
then
    sudo pacman -Sy docker docker-compose --noconfirm
    sudo usermod -aG docker ${USER}
    sudo systemctl enable docker
    sudo systemctl start docker
fi


#grab scripts
git clone https://github.com/kapi00z/script.git -D ~/script

#grab docker-scripts
mkdir -p ~/docker
git clone https://github.com/kapi00z/docker-scripts.git -D ~/docker/docker-scripts