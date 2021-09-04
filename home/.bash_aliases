#!/usr/bin/env bash

# program aliases
alias ca="qalc"
alias k='kubectl'
alias ll='ls -l'
alias ff='firefox'
alias o="openfromterm.sh"

# system control
alias reboot='systemctl reboot'
alias poweroff='systemctl poweroff'
alias suspend='systemctl suspend'

# trash
alias del='trash-put'
#alias rm='echo Use \"del\", or the full path i.e: /bin/rm'

# youtube downloader
alias yta='youtube-dl --ignore-errors --output "%(artist)s - %(track)s.%(ext)s" --extract-audio --audio-format mp3 --embed-thumbnail --add-metadata'
alias yt='youtube-dl --ignore-errors --output "%(uploader)s - %(title)s.%(ext)s"'
alias ytm="$HOME/bin/youtubemusicdownloader.py"

# fun
# script: "curl -L http://bit.ly/10hA8iC | bash"
alias rick="$HOME/bin/rick.sh"
# repo: https://github.com/oakes/vim_cubed
alias vim3="$HOME/.nimble/bin/vim3"

# colors
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ls='ls --color=auto'

# matlab
alias matlab="$HOME/MATLAB/R2020a/bin/matlab -nodesktop -nosplash"
alias matlab-desktop="$HOME/MATLAB/R2020a/bin/matlab"

# ssh
alias ssh="kitty +kitten ssh"
