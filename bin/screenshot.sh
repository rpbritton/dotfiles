#!/bin/bash

directory="$HOME/tmp/screenshots"
name='screenshot_%F_%T_$wx$h.png'

mkdir -p "$directory"

scrot "$directory/$name" -e 'xclip -selection clipboard -target image/png -i $f' $@
cp $(find $directory -type f | sort | tail -1) $directory/latest_screenshot.png
