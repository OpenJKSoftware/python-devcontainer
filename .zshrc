export PATH="$HOME/.local/bin:$PATH"

# Initialize Starship prompt
eval "$(starship init zsh)"

fpath+=~/.zfunc
autoload -Uz compinit && compinit
HISTFILE=~/.commandhistory/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt nocorrectall; setopt correct
