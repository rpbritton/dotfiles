#
# ~/.bashrc
#

# exit if not running interactively
[[ $- != *i* ]] && return

# inclusions
[[ -f $HOME/.bash_path ]] && source $HOME/.bash_path
[[ -f $HOME/.bash_variables ]] && source $HOME/.bash_variables
[[ -f $HOME/.bash_aliases ]] && source $HOME/.bash_aliases

# pywal colors
[[ -f $HOME/.cache/wal/sequences ]] && cat $HOME/.cache/wal/sequences

# bash prompt
export PS1="\[$(tput bold)\]\[$(tput setaf 2)\]\w\[$(tput bold)\]\[$(tput setaf 4)\] \\$\[$(tput sgr0)\] \[$(tput sgr0)\]"

