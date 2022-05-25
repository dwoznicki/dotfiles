# Install the following packages:
# - ripgrep: grep alternative
# - fd-find: find alternative
# - xclip: access the system clipboard from the command line
# - curl: standard network tool
apt --version
if [ $? -eq 0 ]; then
    echo "Found \`apt\` binary. Installing some utilities with \`apt\`."
    sudo apt install ripgrep fd-find xclip curl
fi

# Insall Starship.rs, which provides a nice command line prompt.
# https://starship.rs/
starship --version
if [ $? -ne 0 ]; then
    curl -sS https://starship.rs/install.sh | sh
fi

# Install nvm, a node.js version manager.
# https://github.com/nvm-sh/nvm
nvm --version
if [ $? -ne 0 ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
fi

# Install vim-plug, a vim package manager.
# https://github.com/junegunn/vim-plug
if [ ! -f "~/.local/share/nvim/site/autoload/plug.vim" ]; then
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
fi

