#!/bin/sh

tail_sleep_time=2

notificationID="4277893"

if [[ $* == "--tail" ]]
then
	while true
	do
		if [[ $(pamixer --get-mute) == "true" ]]
		then
			echo "muted"
		else
			echo $(pamixer --get-volume)%
		fi

		sleep $tail_sleep_time &
		wait $!
	done
	exit 1
fi

if pamixer $*
then
	if [[ $(pamixer --get-mute) == "true" ]]
	then
		append_mute=" - muted"
	fi

	volume=$(pamixer --get-volume)
	volume_bar="[$(printf "%*s" $(($volume/5)) | tr " " "+")x$(printf "%*s" $((20-$volume/5)) | tr " " "-")]"

	dunstify -r $notificationID "Volume:" "$volume_bar  =>  $volume%$append_mute" -t 2000

	pgrep volume | while read loop_pid
	do
		pkill -P $loop_pid sleep
	done
fi
