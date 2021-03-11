#!/bin/sh

# LAYOUT="colemak"
LAYOUT="ckl"

while test $# -gt 0
do
	case "$1" in
		-l|--layout)
			LAYOUT=$2
			shift 2
			;;
		*)
			echo "unexpected: '$1'"
			exit 1
			;;
	esac
done

xset -b
xsetroot -cursor_name left_ptr

#xset r rate 250 40

# bash $HOME/git/BigBagKbdTrixXKB/setxkb.sh -k -o "misc:extend,lv5:caps_switch_lock,compose:menu" -l "$LAYOUT" -m pc104
# xkbset mousekeys

#setxkbmap -option ''
#setxkbmap -v 9 -model pc104 -layout "$LAYOUT" -option ''

# pkill -USR1 -x sxhkd

# fix repeating
# seq -s " r " 8 255 | xargs xset r