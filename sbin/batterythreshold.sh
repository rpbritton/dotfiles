#!/bin/bash

errmsg="Usage: ./batterythreshold.sh [low,high]|none|read"

if [[ "$EUID" != 0 ]]
then
	echo "Please run as root"
	exit 1
fi

if [[ $# == 0 ]]
then
	echo $errmsg
	exit 1
fi

case $1 in
	read) smbios-battery-ctl --get-charging-cfg; exit 0;;
	none) smbios-battery-ctl --set-charging-mode=standard; exit 0;;
	*,*)
		if ! [[ $1 =~ [0-9]+,[0-9]+ ]]
		then
			echo $errmsg
			exit 1
		fi

		start_thresh=$(echo $1 | cut -d "," -f 1)
		end_thresh=$(echo $1 | cut -d "," -f 2)
		smbios-battery-ctl --set-custom-charge-interval=$start_thresh $end_thresh
		smbios-battery-ctl --set-charging-mode=custom
		;;
	*)
		echo $errmsg
		exit 1
		;;
esac
