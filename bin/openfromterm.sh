#!/bin/bash

# get the window id
TERM_WINDOW_ID=$WINDOWID
[[ -z $TERM_WINDOW_ID ]] && echo "could not get terminal window id" && exit 1

# hide the terminal window
bspc node $TERM_WINDOW_ID --flag hidden=on

# open the application
xdg-open $@

# reshow the terminal
bspc node $TERM_WINDOW_ID --flag hidden=off
