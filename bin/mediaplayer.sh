#!/bin/sh

HELP_MSG="usage: ./mediaplayer.sh [--select] status|play|pause|toggle|next"

# print a player
function print_player() {
    PLAYER=$1
# player=$(unbuffer playerctl -l 2>&1 | head -n 1)
# if [[ -z $player || $player == "No players were found" ]]
# then
# 	echo
# else
# 	state=$(unbuffer playerctl -p $player status | tr '[:upper:]' '[:lower:]')
# 	metadata=$(unbuffer playerctl -p $player metadata 2>&1)
# 	if [[ $metadata == "No player could handle this command" ]]
# 	then
# 		echo "$state: $player"
# 	else
# 		title=$(unbuffer playerctl -p $player metadata title 2>&1)
# 		artist=$(unbuffer playerctl -p $player metadata artist 2>&1)

# 		formatted_title=$(echo $title | cut -c 1-16 | iconv -c -f utf-8 -t ascii)
# 		formatted_artist=$(echo $artist | cut -c 1-16 | iconv -c -f utf-8 -t ascii)

# 		if [[ -z $title || $title == "No player could handle this command" ]]
# 		then
# 			echo "$state: $player"
# 		elif [[ -z $artist || $artist == "No player could handle this command" ]]
# 		then
# 			echo "$state: $formatted_title"
# 		else
# 			echo "$state: $formatted_title - $formatted_artist"
# 		fi
# 	fi
# fi
    echo temp
}

# print all players
function print_all_players() {
    while read PLAYER
    do
        # [[ -z $PLAYER ]] && exit
        echo $PLAYER
    done <<<$(unbuffer playerctl -l 2>&1)
}

# get the active player
function get_active_player() {
    PLAYER=$(unbuffer playerctl -l 2>&1 | head -n 1)
}

# select a player with rofi
function select_a_player() {
     print_all_players | rofi -dmenu -p "player:" -no-custom
}

# # logic of running the script
# if [[ -z $ROFI_RETV ]]
# then
#     # parse arguments
#     while [[ $# -gt 0 ]]
#     do
#         case $1 in
#             status|play|pause|toggle|next) ACTION=$1; shift ;;
#             -s|--select) SELECT=true; shift ;;
#             *) echo $HELP_MSG; exit 1 ;;
#         esac
#     done
#     [[ -z $ACTION ]] && echo $HELP_MSG && exit 1

#     # run selector or auto select
#     if [[ -z $SELECT ]]
#     then
#         PLAYER=$(unbuffer playerctl -l 2>&1 | head -n 1)
#     else
#         rofi -show player -modi "player:$0"
#     fi
# else
#     echo -en "\x00no-custom\x1ftrue\n"
#     echo -en "\0message\x1fChange prompt\n"

#     case $ROFI_RETV in
#         0) print_all_players ;;
#         1) PLAYER=$1 ;;
#     esac
# fi

# echo $ACTION: $PLAYER

# parse arguments
while [[ $# -gt 0 ]]
do
    case $1 in
        --choose) CHOOSE=true; shift ;;
        *) ACTION=$*; break ;;
    esac
done

# select the player
if [[ -z CHOOSE ]]
then
    PLAYER=$(get_active_player)
else
    PLAYER=$(select_a_player)
fi

echo $ACTION