#!/bin/sh

tail_sleep_time=10
notificationID=5523978
brightnesses=(0 1 2 3 4 5 10 20 30 40 50 60 70 80 90 100)
errormsg="Usage: ./backlight.sh [--tail] [brightness]"

get_index() {
	brightness=$(light -G | cut -d "." -f 1)
	lower_index=

	for index in ${!brightnesses[@]}
	do
		if [[ $brightness == ${brightnesses[$index]} ]]
		then
			return
		fi
		if [[ $brightness -lt ${brightnesses[$index]} ]]
		then
			lower_index=$((index - 1))
			return
		fi
	done
}

set_brightness() {
	index=$1
	if [[ $index -lt 0 ]]
	then
		index=0
	elif [[ $index -gt $((${#brightnesses[@]} - 1)) ]]
	then
		index=$((${#brightnesses[@]} - 1))
	fi
	light -S ${brightnesses[$index]}

	brightness=$(light -G | cut -d "." -f 1)
	brightness_bar="[$(printf "%*s" $(($brightness/5)) | tr " " "+")x$(printf "%*s" $((20-$brightness/5)) | tr " " "-")]"
	dunstify -r $notificationID "Brightness:" "$brightness_bar  =>  $brightness%" -t 2000
	pgrep backlight | while read loop_pid
	do
		pkill -P $loop_pid sleep
	done
}

case $1 in
	--tail)
		while true
		do
			echo $(light -G 2>&1 | tail -1 | cut -d "." -f 1)%

			sleep $tail_sleep_time &
			wait $!
		done
		exit 1
		;;
	-*)
		amount=$(echo $1 | cut -d "-" -f 2)
		[[ -z $amount ]] && amount=1
		get_index
		set_brightness $((index - amount))
		;;
	+*)
		amount=$(echo $1 | cut -d "+" -f 2)
		[[ -z $amount ]] && amount=1
		get_index
		set_brightness $((index + amount))
		;;
	*)
		set_brightness $1
		;;
esac

#if light $*
#then
	#brightness=$(light -G | cut -d "." -f 1)

	#for i in ${!brightnesses[@]}
	#do
		#if [[ $brightness -lt ${brightnesses[$i]} ]]
		#then
			#light -S ${brightnesses[$i]}
			#break
		#fi
	#done

	#brightness_bar="[$(printf "%*s" $(($brightness/5)) | tr " " "+")x$(printf "%*s" $((20-$brightness/5)) | tr " " "-")]"
	#dunstify -r $notificationID "Brightness:" "$brightness_bar  =>  $brightness%" -t 2000
	#pgrep backlight | while read loop_pid
	#do
		#pkill -P $loop_pid sleep
	#done
#fi
