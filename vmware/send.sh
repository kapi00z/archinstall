#!/bin/bash

arg="$1"

if [[ $arg == "" ]]
then
    if [[ $test == "" ]]
    then
        read -p 'Enter test IP: ' addr
    else
        addr="$test"
    fi
else
    addr="$arg"
fi

sed -i "/$addr/d" ~/.ssh/known_hosts
sshpass -p kacpi ssh -o StrictHostKeyChecking=no root@$addr uname -r
sshpass -p kacpi scp $PWD/install.sh root@${addr}:/root
sshpass -p kacpi scp $PWD/setup.sh root@${addr}:/root
sed -i "/$addr/d" ~/.ssh/known_hosts