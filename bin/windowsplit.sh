#!/bin/sh

#bspc rule -a -o $(bspc query -N -n focused) split_dir=south
bspc rule -a "*" split_dir=down
