#!/bin/bash

if [[ -z $ROFI_RETV ]]
then
    if [[ $# -gt 0 ]]
    then
        echo 'usage: ./changevpngui.sh'
    else
        rofi -show vpn -modi "vpn:$0"
    fi
else
    echo -en "\x00no-custom\x1ftrue\n"

    case $ROFI_RETV in
        0) sudo changevpn.sh -l ;;
        1) sudo changevpn.sh -s $1 ;;
    esac
fi