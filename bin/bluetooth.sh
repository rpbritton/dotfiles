#!/bin/sh

tail_sleep_time=10

notification_id=4277897
notification_time=4000

while [[ $# -gt 0 ]]
do
    case $1 in
        -e|--enable)
            shift 1
            action="enable"
        ;;
        -c|--connect)
            shift 1
            action="connect"
        ;;
        -d|--disable)
            shift 1
            action="disable"
        ;;
        -t|--toggle)
            shift 1
            if [[ $(bluetoothctl show | grep "Powered: no") ]]
            then
                action="enable"
            else
                action="disable"
            fi
        ;;
        --toggle-connect)
            shift 1
            if [[ $(bluetoothctl show | grep "Powered: no") ]]
            then
                action="connect"
            else
                action="disable"
            fi
        ;;
        --state)
            shift 1
            if [[ "$1" == "short" ]]
            then
                if [[ $(bluetoothctl info | grep "Connected: yes") ]]
                then
                    echo "conn"
                elif [[ $(bluetoothctl show | grep "Powered: yes") ]]
                then
                    echo "on"
                else
                    echo "off"
                fi
            else
                if [[ $(bluetoothctl info | grep "Connected: yes") ]]
                then
                    echo "Connected to $(bluetoothctl info | grep Name | cut -d " " -f 2-)"
                elif [[ $(bluetoothctl show | grep "Powered: yes") ]]
                then
                    echo "Powered on"
                else
                    echo "Powered off"
                fi
            fi
        ;;
        --tail)
            shift 1
            while true
            do
                "$0" --state $1
                
                sleep $tail_sleep_time &
                wait $!
            done
            shift 1
        ;;
        *)
            shift 1
        ;;
    esac
done

case $action in
    enable)
        bluetoothctl power on
    ;;
    disable)
        bluetoothctl power off
    ;;
    connect)
        #bluetoothctl power on
        device=$(bluetoothctl devices Paired | cut -d " " -f 3- | rofi -dmenu -p "device" -no-custom)
        if [[ ! -z $device ]]
        then
            #if [[ $($0 --state short) == "on" ]]
            #then
            #bluetoothctl power off
            #fi
            #else
            device_id=$(bluetoothctl devices Paired | grep "$device" | cut -d " " -f 2)
            if [[ -z $(bluetoothctl info $device_id | grep "Connected: yes") ]]
            then
                bluetoothctl power on
                bluetoothctl connect $device_id
            else
                bluetoothctl disconnect $device_id
            fi
        fi
    ;;
esac

pgrep "bluetoothnotify" | while read loop_pid
do
    pkill -P $loop_pid sleep
done
