#!/bin/sh

default_wallpaper="$HOME/Pictures/wallpaper.png"

#if [ -e $HOME/.cache/wal/colors.sh ];
#then
	#. $HOME/.cache/wal/colors.sh
#fi

while [[ $# -gt 0 ]]
do
	case $1 in
		-f|--fit)
			fit=true
			shift
			;;
		-b|--background)
			background_style=$2
			shift 2
			;;
		-p|--picture)
			source_type=file
			wallpaper=$2
			shift 2
			;;
		-d|--directory)
			source_type=directory
			wallpaper=$2
			shift 2
			;;
		-u|--url)
			source_type=url
			wallpaper=$2
			shift 2
			;;
		*)
			echo "Unknown option: $*"
			exit 1
	esac
done

if [[ $source_type == "url" ]]
then
	wget "$url" -O /tmp/remote_wallpaper.png
	wallpaper="/tmp/remote_wallpaper.png"
fi

if [[ $wallpaper == "" ]]
then
	wallpaper=$default_wallpaper
fi

if ! identify "$wallpaper" > /dev/null 2>&1
then
	exit 1
fi

convert "$wallpaper" "$HOME/Pictures/wallpaper.png"

wal -c
wal -a 95 -i "$wallpaper" -n

background_color=gray58
shadow_color=black
if [ -e $HOME/.cache/wal/colors.sh ];
then
	. $HOME/.cache/wal/colors.sh
	background_color=$color1
	shadow_color=$color0
fi

if [[ $fit == true ]]
then
	if [[ $background_style == "blur" ]]
	then
		convert "$wallpaper" \
			\( -clone 0 -modulate 70,70 -resize 480x270^ -gravity center -extent 480x270 -blur 0x2 -resize 3840x2160^ \) \
			\( -clone 0 -resize 3840x2160 \) \
			\( +clone -background $shadow_color -shadow 80x20+0+0 \) \
			\( -clone 3 -clone 2 -background none -layers merge +repage \) \
			-delete 0,2,3 -gravity center -compose over -composite \
			"$default_wallpaper"
	else
		convert $wallpaper \
			\( -clone 0 -resize 3840x2160 \) \
			\( +clone -background $shadow_color -shadow 80x20+0+0 \) \
			\( -clone 2 -clone 1 -background none -layers merge +repage \) \
			-delete 0,1,2 -gravity center -background $background_color -extent 3840x2160 \
			"$default_wallpaper"
	fi
	wallpaper=$default_wallpaper
fi

# set background
feh --bg-fill "$wallpaper"

# set bspwm
bspc config normal_border_color $color0
bspc config focused_border_color $color1
bspc config active_border_color $color1
bspc config presel_feedback_color $color1

# set dunst
if [[ $(pgrep "dunst") ]]
then
	pkill dunst
	dunst \
	-frame_width 0 \
        -lb "${color0}" \
        -nb "${color0}" \
        -cb "${color2}" \
        -lf "${color7}" \
        -nf "${color7}" \
        -cf "${color7}" &
fi

# set polybar
#polybar-msg cmd restart

#qutebrowser :config-source
