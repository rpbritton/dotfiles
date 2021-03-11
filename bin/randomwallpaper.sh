#!/bin/sh

unsplash_url="https://source.unsplash.com/random/3840x2160/?"
reddit_limit=10

if [ -e $HOME/.cache/wal/colors.sh ];
then
	. $HOME/.cache/wal/colors.sh
fi

while [[ $# -gt 0 ]]
do
	case $1 in
		-r|--reddit)
			picture_source=reddit
			subreddit=$2
			shift 2
			;;
		-u|--unsplash)
			picture_source=unsplash
			search_terms=$2
			shift 2
			;;
		-d|--directory)
			picture_source=directory
			directory=$2
			shift 2
			;;
		*) 
			pass_params=$*
			shift $#
			;;
	esac
done

if [[ $picture_source == unsplash ]]
then
	url="$unsplash_url$search_terms"

	wget --spider $url
	if [[ $? -eq 0 ]]
	then
		wget -O $HOME/Pictures/wallpaper.png $url
		$HOME/bin/setwallpaper.sh $pass_params -d $HOME/Pictures/wallpaper.png
	fi
elif [[ $picture_source == reddit ]]
then
	json=$(wget -O- "https://www.reddit.com/r/$subreddit/hot.json?limit=${reddit_limit}")
	if [[ $? -eq 0 ]]
	then
		shuf -i 0-$((${reddit_limit}-1)) | while read i
		do
			if [[ $(jq -r ".data.children[$i].data.post_hint" <<< $json) == "image" ]] || \
				[[ $(jq -r ".data.children[$i].data.stickied" <<< $json) != "true" ]]
			then
				file=$(jq -r ".data.children[$i].data.url" <<< $json)
				wget $file -O "$HOME/Pictures/wallpaper.png"
				$HOME/bin/setwallpaper.sh $pass_params -d "$HOME/Pictures/wallpaper.png"
				break
			fi
		done
	fi
elif [[ $picture_source == directory && -d $directory ]]
then
	find $directory -type f | sort -R | while read file
	do
		if identify $file > /dev/null 2>&1
		then
			$HOME/scripts/setwallpaper.sh $pass_params -d $file
			exit
		fi
	done
fi
