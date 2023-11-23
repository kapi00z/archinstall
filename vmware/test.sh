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

scp $PWD/install.sh root@${addr}:~
scp $PWD/setup.sh root@${addr}:~