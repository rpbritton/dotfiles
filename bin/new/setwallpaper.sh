#!/bin/sh

CURRENT_WALLPAPER="$HOME/Pictures/wallpaper.png"
WALLPAPER=$CURRENT_WALLPAPER

# parse options
while [[ $# -gt 0 ]]
do
	case $1 in
		--fit) FIT=true ;;
		--blur) BLUR=true ;;
        -h|--help)
            echo "usage: wallpaperloop.sh [--fit] [--blur] wallpaper.png"
            exit
            ;;
		*)
			WALLPAPER=$1
	esac
    shift
done

# make sure is valid wallpaper
if [[ -z $WALLPAPER ]]
then
	echo "no wallpaper provided"
	exit 1
fi
if ! identify "$WALLPAPER" > /dev/null 2>&1
then
	echo "invalid wallpaper '$WALLPAPER'"
	exit 1
fi

# create background image
if [[ $FIT ]]
then
	if [[ $BLUR ]]
	then
		convert "$WALLPAPER" \
			\( -clone 0 -modulate 70,70 -resize 480x270^ -gravity center -extent 480x270 -blur 0x2 -resize 3840x2160^ \) \
			\( -clone 0 -resize 3840x2160 \) \
			\( +clone -background black -shadow 80x20+0+0 \) \
			\( -clone 3 -clone 2 -background none -layers merge +repage \) \
			-delete 0,2,3 -gravity center -compose over -composite \
			"$CURRENT_WALLPAPER"
	else
		convert $WALLPAPER \
			\( -clone 0 -resize 3840x2160 \) \
			\( +clone -background black -shadow 80x20+0+0 \) \
			\( -clone 2 -clone 1 -background none -layers merge +repage \) \
			-delete 0,1,2 -gravity center -background gray58 -extent 3840x2160 \
			"$CURRENT_WALLPAPER"
	fi
elif [[ $WALLPAPER != $CURRENT_WALLPAPER ]]
then
	cp $WALLPAPER $CURRENT_WALLPAPER
fi

# remove old wallpapers from wpg
while read OLD
do
	if [[ ! -z $OLD ]]
	then
		wpg -d $OLD
	fi
done <<<$(wpg -l)

# set wallpaper
wpg -a $CURRENT_WALLPAPER
wpg -s $(basename $CURRENT_WALLPAPER)

wal -c
wal -a 95 -i $CURRENT_WALLPAPER -n
