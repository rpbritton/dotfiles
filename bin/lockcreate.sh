#!/bin/sh

#img_path="$HOME/Pictures/calvinandhobbes/*.gif"
img_path="$HOME/Comics/mutts"
#img_path="$HOME/Pictures/lock.png"

while [[ $# -gt 0 ]]
do
	case $1 in
		-p|--picture)
			shift
			img_path=$1
			shift
			;;
		*)
			shift
	esac
done

if [[ -d $img_path ]]
then
	while read file <<< $(find $img_path -type f | sort -R)
	do
		if identify $file > /dev/null 2>&1
		then
			img_path=$file
			break
		fi
	done
fi

if ! identify "$img_path" > /dev/null 2>&1
then
	echo "Invalid image path (not a picture or no picture found)!"
	exit 1
fi

monitor_info=$(xrandr --listactivemonitors | grep '*' | cut -d ' ' -f4)
monitor_w=$(echo $monitor_info | cut -d 'x' -f1 | cut -d '/' -f1)
monitor_h=$(echo $monitor_info | cut -d 'x' -f2 | cut -d '/' -f1)
monitor_x=$(echo $monitor_info | cut -d '+' -f2)
monitor_y=$(echo $monitor_info | cut -d '+' -f3)
picture_bounds_w=$(echo "$monitor_w * 0.75" | bc | cut -d '.' -f1)
picture_bounds_h=$(echo "$monitor_h * 0.75" | bc | cut -d '.' -f1)

shadow_color=black
if [[ -e $HOME/.cache/wal/colors.sh ]]
then
	. $HOME/.cache/wal/colors.sh
	shadow_color=$color0
fi

scrot -o /tmp/lock.png

convert /tmp/lock.png -scale 10% -scale 1000% \
	\( "$img_path" -resize "$picture_bounds_w"x"$picture_bounds_h" -background none -gravity center -extent "$monitor_w"x"$monitor_h" -gravity none -geometry +"$monitor_x"+"$monitor_y" \) \
	\( -clone 1 -background $shadow_color -shadow 50x10+5+5 \) \
	\( -clone 2 -clone 1 -background none -layers merge +repage \) \
	-delete 1,2 -composite \
	/tmp/lock.png
