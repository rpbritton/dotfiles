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
export PS1="\[\033[01;32m\]\u@\h \[\033[01;34m\]\W \\$ \[\033[00m\]"

