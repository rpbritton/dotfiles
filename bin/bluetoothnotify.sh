#!/bin/sh

sleep_time=2

notification_id=4277895
notification_time=4000

for pid in $(pgrep "bluetoothnotify")
do
	if [[ $$ != $pid ]]
	then
		echo "Script is already running!"
		exit 1
	fi
done

prev_state=$($HOME/bin/bluetooth.sh --state)

while true
do
	state=$($HOME/bin/bluetooth.sh --state)

	if [[ "$prev_state" != "$state" ]]
	then
		if [[ $prev_state == "Connected to"* ]] && [[ "$state" == "Powered on" ]] && [[ ! $(pgrep bluetoothctl) ]]
		then
			$HOME/bin/bluetooth.sh --disable
		fi

		dunstify -r $notification_id "Bluetooth:" "$state" -t $notification_time

		pgrep "bluetooth.sh" | while read loop_pid
		do
			pkill -P $loop_pid sleep
		done

		prev_state=$state
	fi

	sleep $sleep_time &
	wait $!
done

