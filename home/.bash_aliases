#!/usr/bin/env bash

# program aliases
alias ca="qalc"
alias k='kubectl'
alias ll='ls -l'
alias ff='firefox'
alias o="openfromterm.sh"
alias c="xclip -selection clipboard"
alias v="xclip -o"
alias toletter="pdfjam --paper letter --outfile"

# system control
alias reboot='systemctl reboot'
alias poweroff='systemctl poweroff'
alias suspend='systemctl suspend'

# trash
alias del='trash-put'
#alias rm='echo Use \"del\", or the full path i.e: /bin/rm'

# youtube downloader
alias yta='youtube-dl --force-ipv4 --ignore-errors --output "%(artist)s - %(track)s.%(ext)s" --extract-audio --audio-format mp3 --embed-thumbnail --add-metadata'
alias yt='youtube-dl --force-ipv4 --ignore-errors --output "%(uploader)s - %(title)s.%(ext)s"'
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
alias watch='watch --color'

# matlab
alias matlab="$HOME/MATLAB/R2020a/bin/matlab -nodesktop -nosplash"
alias matlab-desktop="$HOME/MATLAB/R2020a/bin/matlab"

# ssh
alias ssh="kitty +kitten ssh"

# file system closne
alias rsyncclone="rsync -aPHAXS"

# run melt script
alias run_melt_script="melt -progress"

# sycamore nas mount
alias mount_sycamore_nas="rclone mount -v --dir-cache-time 30s sycamore:/nas /nas"
alias mount_daemon_sycamore_nas="mount_sycamore_nas --daemon"
alias unmount_daemon_sycamore_nas="fusermount -u /nas"

# package manager
alias pacman_rebuild_dryrun="checkrebuild"
alias pacman_rebuild="yay -S --rebuild --answerclean A --answerdiff N \$(checkrebuild | cut -d $'\t' -f 2)"
alias pacman_clean_uninstalled_dryrun="paccache -dvuk0"
alias pacman_clean_uninstalled="paccache -rvuk0"
alias pacman_remove_orphans_dryrun="yay -Qdtq"
alias pacman_remove_orphans="yay -Rsn \$(yay -Qdtq)"

