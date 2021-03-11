#!/bin/bash

errmsg="Unknown command. Usage: ./createvoc.sh CONFIG.JSON"

if [[ $# != 1 ]]
then
	echo $errmsg
	exit 1
fi

if [[ ! -f "$1" ]]
then
	echo $errmsg
	exit 1
fi

if ! cat $1 | jq > /dev/null 2>&1
then
	echo "Bad config JSON"
	exit 1
fi

tmpdir=$(mktemp -d)
filelist=""

while read fileproperties
do
	file=$(echo $fileproperties | jq -r '.file')
	if [[ ! -f "$file" ]]
	then
		echo "Not a file: $fileproperties"
		continue
	fi
	tmpfile="$tmpdir/$(basename "$file" | cut -d "." -f 1).pdf"

	label=$(echo $fileproperties | jq -r '.label')
	if [[ "$label" != "null" ]]
	then
		convert -background '#00000080' \
			-fill white -font "IBM-Plex-Sans-Bold" -pointsize 78 \
			label:"$label" miff:- |\
			composite -gravity northwest -geometry +0+0 -density 300 -quality 900 \
			- "$file" "$tmpfile"
	elif identify "$file" > /dev/null 2>&1
	then
		convert -density 300 -quality 900 "$file" "$tmpfile"
	else
		convert -density 300 -quality 900 "$file" "$tmpfile"
	fi

	# scaling
	mediabox=$(cpdf -page-info "$tmpfile" | grep "MediaBox" | head -1)
	width=$(echo "$mediabox" | awk '{ print $4 - $2 }' | cut -d "." -f 1)
	height=$(echo "$mediabox" | awk '{ print $5 - $3 }' | cut -d "." -f 1)
	if [[ $width -ge $height ]]
	then
		cpdf -scale-page "11in div PW 11in div PW" "$tmpfile" -o "$tmpfile"
	else
		cpdf -scale-page "11in div PH 11in div PH" "$tmpfile" -o "$tmpfile"
	fi

	filelist+="$tmpfile "
done < <(cat "$1" | jq -cr '.files[]')

finalfile=$(cat "$1" | jq -cr '.output')
eval "cpdf $filelist -o $finalfile"

# ocrmypdf -q --skip-text --threshold "$finalfile" "$finalfile"

#cpdf -remove-metadata "$finalfile" -o "$finalfile"
cpdf -set-author "" "$finalfile" -o "$finalfile"
cpdf -set-title "" "$finalfile" -o "$finalfile"
cpdf -set-subject "" "$finalfile" -o "$finalfile"
cpdf -set-keywords "" "$finalfile" -o "$finalfile"
cpdf -set-create "" "$finalfile" -o "$finalfile"
cpdf -set-modify "" "$finalfile" -o "$finalfile"
cpdf -set-creator "" "$finalfile" -o "$finalfile"
cpdf -set-producer "" "$finalfile" -o "$finalfile"

rm -r "$tmpdir"
