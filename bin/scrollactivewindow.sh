#!/bin/bash

helpmsg="Usage: ./scrollactivewindow.sh [up|down|back|forward]"

if [[ $# != 1 ]]
then
	echo $helpmsg
	exit 1
fi

case $1 in
	up) BUTTON=4 ;;
	down) BUTTON=5 ;;
	back) BUTTON=8 ;;
	forward) BUTTON=9 ;;
	*)
		echo $helpmsg
		exit 1
esac

eval $(xdotool getwindowgeometry --shell $(xdotool getactivewindow))
WINX=$X
WINY=$Y
eval $(xdotool getmouselocation --shell)

#echo $X $Y $WINX $WINY $WIDTH $HEIGHT $((WINY + HEIGHT)) $((WINX + WIDTH))

if (( X < WINX || \
	X > WINX + WIDTH || \
	Y < WINY || \
	Y > WINY + HEIGHT ))
then
	xdotool mousemove $((WINX + WIDTH / 2)) $((WINY + HEIGHT / 2)) \
		click $BUTTON \
		mousemove restore
else
	xdotool click $BUTTON
fi

