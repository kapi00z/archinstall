#!/bin/bash

args=($@)

if [[ ${args[0]} == "" ]]
then
    read -p 'Enter test IP: ' addr
else
    addr="192.168.1.${args[0]}"
fi

sed -i "/$addr/d" ~/.ssh/known_hosts
sshpass -p kacpi ssh -o StrictHostKeyChecking=no root@$addr uname -r
sshpass -p kacpi scp $PWD/install.sh root@${addr}:/root
sshpass -p kacpi scp $PWD/setup.sh root@${addr}:/root
sshpass -p kacpi ssh -o StrictHostKeyChecking=no root@$addr bash install.sh ${args[@]:1}
sed -i "/$addr/d" ~/.ssh/known_hosts