#!/bin/bash

function install {
    echo "Installing GUI..."
    pacman -S xorg plasma sddm kde-applications nvidia dolphin chromium --noconfirm

    systemctl enable sddm
}

read -p 'Install GUI?: ' input

answer="$(echo $input | tr '[:upper:]' '[:lower:]')"

case $answer in

    y | yes)
        install
        ;;
    
    n | no)
        echo "Not installing gui..."
        ;;

    "")
        echo "Assuming yes..."
        install
        ;;
    
    *)
        echo "Answer not recognized"
        ;;
    
esac