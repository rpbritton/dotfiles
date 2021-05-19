#!/bin/bash

ERR_USAGE='Usage: ./changevpn.sh [-l|-s] vpn'
ERR_UNKNOWN_VPN='Unknown vpn'

function list_vpns() {
	find -O1 /etc/openvpn/client/ -name *.conf | xargs basename -s .conf
	echo "none"
}

function set_vpn() {
	local VPN=$1
	[[ -z $VPN || -z $(list_vpns | grep "^$VPN\$") ]] && echo $ERR_UNKNOWN_VPN && exit 1

	while read ACTIVE_VPN
	do
		[[ -z $ACTIVE_VPN ]] && break
		[[ $ACTIVE_VPN == $VPN ]] && VPN=none && continue
		nohup systemctl disable --now "openvpn-client@$ACTIVE_VPN" > /dev/null 2>&1 &
	done <<<$(active_vpns | grep -v "^$VPN\$")

	if [[ $VPN != "none" ]]
	then
		nohup systemctl enable --now "openvpn-client@$VPN" > /dev/null 2>&1 &
		# enable mace
		nohup sh -c "sleep 20 && curl -s 'http://209.222.18.222:1111/'" > /dev/null 2>&1 &
	fi
}

function active_vpns() {
	pgrep -a openvpn | grep -oP '(?<=\-\-config ).*(?=\.conf)'
}

[[ $# -eq 0 ]] && exit_bad_usage

while test $# -gt 0
do
	case "$1" in
		-s|--set)
			set_vpn $2
			shift 2 ;;
		-l|--list)
			list_vpns
			shift ;;
		*)
			echo $ERR_USAGE && exit 1 ;;
	esac
done
