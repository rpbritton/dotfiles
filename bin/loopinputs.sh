#!/bin/sh

LOCKFILE=/tmp/loopinputs.sh

$HOME/bin/setinputs.sh

if ! lockfile-create --use-pid --retry 0 $LOCKFILE > /dev/null 2>&1
then
    exit
fi

udevadm monitor --udev | while read line
do
    if [[ $line == *" bind "* && $line == *" (hid)" ]]
    then
        $HOME/bin/setinputs.sh
    fi
done