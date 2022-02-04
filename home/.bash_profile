#
# ~/.bash_profile
#

# include bashrc
[[ -f $HOME/.bashrc ]] && source $HOME/.bashrc

# auto start x
if type startx &> /dev/null && [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]
then
	exec startx
fi
