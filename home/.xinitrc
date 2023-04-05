#!/bin/sh

# add xresources
SYS_RESOURCES=/etc/X11/xinit/.Xresources
[[ -f $SYS_RESOURCES ]] && xrdb -merge $SYS_RESOURCES
USR_RESOURCES=$HOME/.Xresources
[[ -f $USR_RESOURCES ]] && xrdb -merge $USR_RESOURCES

# add modmap
SYS_MODMAP=/etc/X11/xinit/.Xmodmap
[[ -f $SYS_MODMAP ]] && xmodmap $SYS_MODMAP
USR_MODMAP=$HOME/.Xmodmap
[[ -f $USR_MODMAP ]] && xmodmap $USR_MODMAP

# start some nice programs
if [[ -d /etc/X11/xinit/xinitrc.d ]]
then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh
    do
        [[ -x $f ]] && . "$f"
    done
    unset f
fi

# set X settings
xset -b
xsetroot -cursor_name left_ptr

exec bspwm

