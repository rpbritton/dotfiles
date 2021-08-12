# bashrc
[[ -f $HOME/.bashrc ]] && source $HOME/.bashrc

# load antigen
source /usr/share/zsh/share/antigen.zsh

# use oh-my-zsh
antigen use oh-my-zsh

# plugins
antigen bundle git
antigen bundle direnv
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-history-substring-search
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-syntax-highlighting

# apply
antigen apply

# autosuggest options
export ZSH_AUTOSUGGEST_STRATEGY=(completion history)
autoload compinit && compinit
export ZSH_AUTOSUGGEST_USE_ASYNC=true

# history options
export HIST_FIND_NO_DUPS=true

# prompt
export PROMPT="%B%F{green}%~%f%b %B%F{blue}%(!.#.$)%f%b "

