#!/bin/bash

set -e

VPN_ON=$(nmcli connection show --active | awk -F ' {2,}' '{ if ($1 == "Gatech VPN" && $3 == "vpn") { print $1 } }' | wc -l)
VPN_NAME="Gatech VPN"

start() {
    [[ $VPN_ON == 1 ]] && return
    
    USER="rbritton6"
    PASSWORD=$(sudo awk -F "=" '/password/ {print $2}' /etc/NetworkManager/system-connections/eduroam.nmconnection)
    SECONDARY="push1"
    GATEWAY="DC Gateway"
    
    eval $({ echo $PASSWORD; sleep 1; echo "$SECONDARY"; sleep 1; echo "$GATEWAY"; } | openconnect --protocol=gp --user=$USER --passwd-on-stdin vpn.gatech.edu --authenticate)

    nmcli connection up "$VPN_NAME" passwd-file /dev/stdin << EOF
    vpn.secrets.cookie:$COOKIE
    vpn.secrets.gwcert:$FINGERPRINT
    vpn.secrets.gateway:$HOST
    vpn.secrets.resolve:$RESOLVE
EOF
}

stop() {
    [[ $VPN_ON == 0 ]] && return
    
    nmcli c down "$VPN_NAME"
}

case $1 in
    start)
        start
    ;;
    
    stop)
        stop
    ;;
    
    *)
        echo "Bad arg: '$1'"
    ;;
esac
