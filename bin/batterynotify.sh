#!/bin/sh

sleep_time=1

notification_id=5389089

for pid in $(pgrep "batterynotify.sh")
do
	if [[ $$ != $pid ]]
	then
		echo "Script is already running!"
		exit 1
	fi
done

prev_state="Full"
prev_percentage=100

while true
do
	info=$(acpi -b)
	state=$(echo $info | cut -d " " -f 3 | cut -d "," -f 1)
	percentage=$(echo $info | cut -d " " -f 4 | cut -d "%" -f 1)

	if [[ $state != $prev_state ]]
	then
		prev_percentage=100
		prev_state=$state
		notify=true
	fi

	if [[ $state == "Discharging" ]] && \
		[[ $percentage -le 20 && $prev_percentage -gt 20 ]] || \
		[[ $percentage -le 15 && $prev_percentage -gt 15 ]] || \
		[[ $percentage -le 10 && $prev_percentage -gt 10 ]] || \
		[[ $percentage -le 5 && $prev_percentage -gt $percentage ]]
	then
		prev_percentage=$percentage
		notify=true
	fi

	if [[ $notify == true ]]
	then
		notify=false
		dunstify -r $notification_id "Battery:" "$state: $percentage%"
	fi

	sleep $sleep_time
done
