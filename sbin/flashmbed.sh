#!/bin/sh

device_label_path="/dev/disk/by-label/MBED"
mnt_path="/tmp/mbed_mnt"

exit_the_program() {
	if [[ $# != 1 ]]
	then
		echo "No exit message"
	else
		echo $1
	fi
	exit 1
}

if [[ "$EUID" != 0 ]]
then
	exit_the_program "Please run as root"
fi

if [[ $# == 0 ]]
then
	exit_the_program "No arguments"
fi

if [[ ! -b "$device_label_path" ]]
then
	exit_the_program "Device not found"
fi

device_path=$(readlink -f $device_label_path)
curr_mnt_path=$(lsblk -o PATH,MOUNTPOINT | tr -s ' ' | grep $device_path | cut -d " " -f 2)

if [[ ! -z "$curr_mnt_path" ]]
then
	end_behavoir=mounted
else
	end_behavoir=unmounted
fi

while [[ $# -gt 0 ]]
do
	case $1 in
		-m|--mount)
			shift 1
			end_behavoir=mounted
			;;
		-u|--unmount)
			shift 1
			end_behavoir=unmounted
			;;
		-f|--file)
			shift 1
			if [[ $# == 0 ]] || [[ ! -f "$1" ]] || [[ "$1" != *".bin" ]]
			then
				exit_the_program "Invalid file parameter"
			fi
			file_path=$1
			shift 1
			;;
		-d|--delete)
			delete_file=true
			shift 1
			;;
		*)
			shift 1
			;;
	esac
done

if [[ ! -z "$file_path" ]]
then
	if [[ -z "$curr_mnt_path" ]]
	then
		echo "mkdir -p \"$mnt_path\""
		mkdir -p "$mnt_path"
		echo "mount \"$device_path\" \"$mnt_path\""
		mount "$device_path" "$mnt_path"
		curr_mnt_path=$mnt_path
	fi

	echo "rm \"$curr_mnt_path/*.bin\""
	rm "$curr_mnt_path/"*".bin"
	echo "cp \"$file_path\" \"$curr_mnt_path/\""
	cp "$file_path" "$curr_mnt_path/"

	if [[ ! -z "$delete_file" ]]
	then
		echo "rm \"$file_path\""
		rm "$file_path"
	fi
fi

if [[ "$end_behavoir" == "mounted" ]]
then
	if [[ -z "$curr_mnt_path" ]]
	then
		echo "mount \"$device_path\" \"$mnt_path\""
		mount "$device_path" "$mnt_path"
		curr_mnt_path=$mnt_path
	fi
else
	if [[ ! -z "$curr_mnt_path" ]]
	then
		echo "umount \"$curr_mnt_path\""
		umount "$curr_mnt_path"
		if [[ "$curr_mnt_path" == "$mnt_path" ]]
		then
			echo "rm -r \"$mnt_path\""
			rm -r "$mnt_path"
		fi
	fi
fi
