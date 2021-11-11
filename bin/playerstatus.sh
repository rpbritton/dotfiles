#!/bin/sh

player=$(unbuffer playerctl -l 2>&1 | head -n 1)
if [[ -z $player || $player == "No players found" ]]
then
	echo
else
	state=$(unbuffer playerctl -p $player status | tr '[:upper:]' '[:lower:]')
	metadata=$(unbuffer playerctl -p $player metadata 2>&1)
	if [[ $metadata == "No player could handle this command" ]]
	then
		echo "$state: $player"
	else
		title=$(unbuffer playerctl -p $player metadata title 2>&1)
		artist=$(unbuffer playerctl -p $player metadata artist 2>&1)

		formatted_title=$(echo $title | cut -c 1-16 | iconv -c -f utf-8 -t ascii)
		formatted_artist=$(echo $artist | cut -c 1-16 | iconv -c -f utf-8 -t ascii)

		if [[ -z $title || $title == "No player could handle this command" ]]
		then
			echo "$state: $player"
		elif [[ -z $artist || $artist == "No player could handle this command" ]]
		then
			echo "$state: $formatted_title"
		else
			echo "$state: $formatted_title - $formatted_artist"
		fi
	fi
fi
