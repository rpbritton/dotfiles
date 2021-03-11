#!/bin/sh

lock_time=12

while test $# -gt 0
do
	case "$1" in
		-e|--enable)
			if [[ $2 =~ "^[0-9]+$" ]]
			then
				$lock_time=$2
			fi
			pkill xautolock
			xautolock -time $lock_time -locker "$HOME/bin/lock.sh --auto" &
			exit
			;;
		-d|--disable)
			pkill xautolock
			exit
			;;
		-t|--toggle)
			if [[ -f /tmp/lock_disable ]]
			then
				rm -f /tmp/lock_disable
			else
				touch /tmp/lock_disable
			fi
			exit
			;;
		-a|--auto)
			auto=true
			shift
			;;
		-f|--force)
			auto=false
			shift
			;;
		*)
			echo "Unknown option: $1"
			exit 1
			;;
	esac
	shift
done

if [[ "$auto" = true && $(pacmd list-sink-inputs | grep "state: RUNNING" | wc -l) -gt 0 ]]
then
	echo "Error: audio detected. Use -f or --force or no parameters to force lock."
	exit 1
fi

for pid in $(pgrep "lock.sh")
do
	if [[ $$ != $pid ]]
	then
		echo "Script is already running!"
		exit 1
	fi
done

if [[ -f "$HOME/.cache/wal/colors.sh" ]]
then
	. $HOME/.cache/wal/colors.sh
fi

if [[ ! -f /tmp/lock.png ]]; then
	$HOME/bin/lockcreate.sh
fi

notify-send "DUNST_COMMAND_PAUSE"
if [[ $(playerctl status) = "Playing" ]]
then
	playerctl pause
fi

if [[ $(light -G | cut -d "." -f 1) -lt 10 ]]
then
	light -S 10
fi

$HOME/bin/setinputs.sh

i3lock -n -i /tmp/lock.png \
	--indicator \
	--insidevercolor=${color0:1}00 \
	--insidewrongcolor=${color0:1}00 \
	--insidecolor=${color0:1}00 \
	--ringvercolor=${color1:1}dd \
	--ringwrongcolor=${color1:1}dd \
	--ringcolor=${color7:1}dd \
	--linecolor=${color0:1}00 \
	--keyhlcolor=${color0:1}dd \
	--bshlcolor=${color0:1}dd \
	--indpos="x+40:y+h-40" \
	--line-uses-inside \
	--radius=16 \
	--veriftext="" \
	--wrongtext="" \
	--force-clock \
	--time-font=monospace \
	--datestr="" \
	--timesize=24 \
	--time-align=2 \
	--timestr="%A, %B %d @ %H:%M" \
	--timepos="x+w-24:iy+4" \
	--timecolor=${color7:1}dd \
	--noinputtext="" 2> /dev/null &
pid=$!

time_waiting=0
while kill -0 $pid 2> /dev/null
do
	time_waiting=$(( $time_waiting + 50 ))
	if (( $time_waiting >= $(( 2 * 60 * 1000 )) ))
	then
		time_waiting=0
		systemctl suspend
		sleep 1
		$HOME/bin/setinputs.sh
	fi
	sleep 0.05
done

notify-send "DUNST_COMMAND_RESUME"

rm /tmp/lock.png
