#!/bin/bash

if [[ $# == 0 ]]
then
	echo "Needs parameter 'on' or 'off'"
	exit 1
fi

if [[ $1 == "on" ]]
then
	nmcli device wifi hotspot ifname wlp1s0 ssid "Aspen" password "watermelon"
elif [[ $1 == "off" ]]
then
	nmcli connection down Hotspot
else
	echo "Unknown parameter '$1'"
fi
