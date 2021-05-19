#
# ~/.bash_profile
#

# include bashrc
[[ -f $HOME/.bashrc ]] && source $HOME/.bashrc

# auto start x
if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]
then
	startx
fi