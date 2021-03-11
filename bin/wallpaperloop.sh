#!/bin/sh

sleep_duration=108000

while [[ $# -gt 0 ]]
do
	case $1 in
		-k|--kill)
			pkill wallpaperloop
			exit
			;;
		-n|--next)
			pgrep wallpaperloop | while read loop_pid
			do
				pkill -P $loop_pid sleep
			done
			exit
			;;
		-s|--sleep)
			shift
			sleep_duration=$1
			shift
			;;
		*)
			pass_params="$*"
			shift $#
			;;
	esac
done

for pid in $(pgrep "wallpaperloop.sh")
do
	if [[ $$ != $pid ]]
	then
		echo "Script is already running!"
		exit 1
	fi
done

while true
do
        sleep $sleep_duration

	if [[ ! $(pgrep "lock.sh") ]]
	then
		$HOME/bin/randomwallpaper.sh $pass_params
	fi
done
