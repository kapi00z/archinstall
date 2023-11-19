#!/bin/bash

setRootPass() {
    echo "root:${pass}" | chpasswd
}

getNetDev() {
    #ip -o link show | awk '{print $2}' | sed '/lo\:/d' | sed 's/\://g'
    netDev=$(ip a | grep -ie '192.168.1.' |  awk '{print $NF}')
    echo $netDev
}

setStaticIP() {
    cat << EOF >> /etc/dhcpcd.conf
interface ${netDev}
static ip_address=${addr}/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.21 192.168.1.1
EOF
}

addUser() {
    useradd -mG kacper
    echo "${user}:${pass}" | chpasswd
    echo "${user} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${user}
}

host="$1"
addr="$2"
user="$3"
pass="$4"

setRootPass
netDev=$(getNetDev)
setStaticIP
addUser