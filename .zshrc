# Add deno completions to search path
if [[ ":$FPATH:" != *":/Users/danwoz/.zsh/completions:"* ]]; then export FPATH="/Users/danwoz/.zsh/completions:$FPATH"; fi
# Enable homebrew.
eval "$(/opt/homebrew/bin/brew shellenv)"

# Enable starship.
eval "$(starship init zsh)"

# Enable Node Version Manager.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Use neovim as default editor.
export EDITOR="nvim"

# Enable autocomplete.
FPATH="$HOME/.zfunc:${FPATH}"
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
autoload -Uz compinit && compinit

# Load ls colors.
export CLICOLOR=1
[ -e "~/.lscolors.sh" ] && source "~/.lscolors.sh"

# Add some aliases.
alias e="nvim"
alias se="sudo nvim"
alias ll="ls -la"

# Add local bin to path.
export PATH="$PATH:$HOME/.local/bin/"

# Load cargo.
[ -e "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Set up pyenv.
which pyenv > /dev/null
if [ $? -eq 0 ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# Load deno.
[ -d "/Users/danwoz/.deno/" ] && . "/Users/danwoz/.deno/env"

# Set up fzf.
which fzf > /dev/null
if [ $? -eq 0 ]; then
    source <(fzf --zsh)
fi
