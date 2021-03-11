#!/bin/bash

LOCK_FILE="/tmp/windowproperties"

# process parameters
while test $# -gt 0
do
	case "$1" in
		-k|--kill)
			if ! kill -9 $(cat "$lock_dir/pid" 2> /dev/null) > /dev/null 2>&1
			then
				echo "Script is not running; cannot be killed"
			fi
			exit
			;;
		*)
			echo "Unexpected: $1"
			exit 1
			;;
	esac
done

# ensure only one instance is running
if ! lockfile-create --use-pid --retry 0 $LOCK_FILE 2> /dev/null
then
	kill $(cat "$LOCK_FILE.lock")
	if ! lockfile-create --use-pid --retry 0 $LOCK_FILE
	then
		echo "Could not kill existing instance"
	fi
fi

# picom shadows only on floating windows
# from: https://www.reddit.com/r/bspwm/comments/ferge0/bspwm_picom_question_about_shadows/fjru76u?utm_source=share&utm_medium=web2x
bspc subscribe node | while read -r line
do
	event=$(echo $line | cut -d " " -f 1)
	if [[ $event == "node_add" ]]
	then
		echo $line
		xprop -id $(echo $line | cut -d " " -f 5) -f _PICOM_NO_SHADOW 32c -set _PICOM_NO_SHADOW 1
	elif [[ $event == "node_state" ]] && [[ $(echo $line | cut -d " " -f 5) == "floating" ]]
	then
		node=$(echo $line | cut -d " " -f 4)
		case $(echo $line | cut -d " " -f 6) in
			on)
				xprop -id "$node" -remove _PICOM_NO_SHADOW
				;;
			off)
				xprop -id "$node" -f _PICOM_NO_SHADOW 32c -set _PICOM_NO_SHADOW 1
				;;
		esac
	fi
done