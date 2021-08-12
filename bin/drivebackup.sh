#!/bin/sh

: '
~/.config/systemd/user/autobackup.timer
------------------------------------
[Unit]
Description=Run a backup every hour
 
[Timer]
OnCalendar=*-*-* *:00:00
Persistent=true
 
[Install]
WantedBy=timers.target
------------------------------------

~/.config/systemd/user/autobackup.service
--------------------------------------
[Unit]
Description=Backup to google drive

[Service]
Type=oneshot
ExecStart=/home/ryan/bin/drivebackup.sh
--------------------------------------

sudo systemctl enable autobackup.timer
'

wget --spider --quiet "http://google.com"
if [ "$?" != 0 ]; then
	echo "No internet!"
	exit 1
fi

. $HOME/bin/secrets/drivesecrets

accounts=( "school" "personal" )

declare -A accounts_to_sync

if [[ $# -eq 0 ]]
then
	for account in "${accounts[@]}"
	do
		accounts_to_sync[$account]=
	done
fi

while [[ $# -gt 0 ]]
do
	case $1 in
		-a|--all)
			for account in "${accounts[@]}"
			do
				accounts_to_sync[$account]=
			done
			shift 1
			;;
		*) 	accounts_to_sync[$1]=
			shift 1
			;;
	esac
done

for account in "${!accounts_to_sync[@]}"
do
	case $account in
		school)
			(unbuffer grive -i $GRIVE_ID -e $GRIVE_SECRET -p "/home/ryan/Georgia Tech" | while read -t 1500 line; do echo $line; done; find "/home/ryan/Georgia Tech/.trash" -type f -mtime +30 -delete) &
			;;
		personal)
			(unbuffer grive -i $GRIVE_ID -e $GRIVE_SECRET -p "/home/ryan/Google Drive" | while read -t 1500 line; do echo $line; done; find "/home/ryan/Google Drive/.trash" -type f -mtime +30 -delete) &
			;;
	esac

	pids+=( $! )
done

for pid in "${pids[@]}"
do
	wait $pid
done
