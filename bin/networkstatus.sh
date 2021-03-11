#!/bin/sh

# TODO: create two polybar modules and have this script print either vpn or network

ETHERNET=$(nmcli connection show --active | awk -F ' {2,}' '{ if ($3 == "ethernet") { print $1 } }' | cut -c 1-32)
WIFI=$(nmcli connection show --active | awk -F ' {2,}' '{ if ($3 == "wifi") { print $1 } }' | cut -c 1-32)

if [[ ! -z $ETHERNET ]]
then
	MSG="eth: $ETHERNET"
elif [[ ! -z $WIFI ]]
then
	MSG="wifi: $WIFI"
else
	MSG="not connected"
fi

# VPN
function ADD_VPN() {
	VPN=$1

	if [[ -z $VPN ]]
	then
		return
	fi

	if [[ -z $VPN_ON ]]
	then
		VPN_ON=true
		MSG="$MSG   vpn: $VPN"
	else
		MSG="$MSG, $VPN"
	fi
}

# network manager
while read VPN
do
	ADD_VPN "$VPN"
done <<<$(nmcli connection show --active | awk -F ' {2,}' '{ if ($3 == "vpn") { print $1 } }' | cut -c 1-32)

# private internet access
while read VPN
do
	ADD_VPN "$VPN"
done <<<$(pgrep -a openvpn | grep -oP '(?<=\-\-config ).*(?=\.conf)')

echo "$MSG"