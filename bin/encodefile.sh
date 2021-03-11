#!/bin/sh

action=encrypt

# process parameters
while test $# -gt 0
do
	case "$1" in
		-d|--decrypt)
			action=decrypt
			shift 1
			;;
		-*)
			echo "unknown option '$1'"
			exit 1
			;;
		*)
			if [[ ! -z $file ]]
			then
				echo "unknown option '$1'"
				exit 1
			fi
			file=$1
			shift 1
			;;
	esac
done

if [[ ! -f $file ]]
then
	echo "unknown file '$file'"
	exit 1
fi

file_extension=$(echo $file | rev | cut -d '.' -f 1 | rev)
if [[ $file_extension == "encrypted" ]] || [[ $file_extension == "decrypted" ]]
then
	output_file=$(echo $file | rev | cut -d '.' -f 2- | rev)
else 
	output_file=$file
fi

if [[ $action == "encrypt" ]]
then
	openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -in $file -out "$output_file.encrypted"
elif [[ $action == "decrypt" ]]
then
	openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -d -in $file -out "$output_file.decrypted"
else
	echo "unknown action '$action'"
fi
