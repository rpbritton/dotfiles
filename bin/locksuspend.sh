#!/bin/sh

# Copy this script into /usr/lib/systemd/system-sleep

if [[ $1 == "pre" ]] && ! pgrep "lock.sh" > /dev/null
then
	su -c "playerctl stop" ryan
	su -c "DISPLAY=:0 /home/ryan/bin/lockcreate.sh" ryan
elif [[ $1 == "post" ]]
then
	sleep 3
	if ! pgrep "lock.sh" > /dev/null
	then
		rm /tmp/lock.png
	fi
fi
