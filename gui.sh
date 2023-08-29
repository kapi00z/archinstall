#!/bin/bash

function install {
    echo "Installing GUI..."
    pacman -S plasma sddm kde-applications nvidia dolphin chromium --noconfirm
}

read -p 'Install GUI?: ' input

answer="$(echo $input | tr '[:upper:]' '[:lower:]')"

case $answer in

    y | yes)
        install
        ;;
    
    n | no)
        echo "no, $answer"
        ;;

    "")
        echo "Assuming yes..."
        install
        ;;
    
    *)
        echo "Answer not recognized"
        ;;
    
esac