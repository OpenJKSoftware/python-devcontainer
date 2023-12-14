export ZSH="$HOME/.oh-my-zsh"
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="crcandy"
HYPHEN_INSENSITIVE="true"
zstyle ':omz:update' mode disabled  # disable automatic updates
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
plugins=(git poetry colored-man-pages docker-compose gitignore pylint fzf)
source $ZSH/oh-my-zsh.sh
fpath+=~/.zfunc
autoload -Uz compinit && compinit
HISTFILE=~/.commandhistory/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt nocorrectall; setopt correct
