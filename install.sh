# Insall Starship.rs, which provides a nice command line prompt.
# https://starship.rs/
starship --version
if [ $? -ne 0 ]; then
    curl -sS https://starship.rs/install.sh | sh
fi

# Install ripgrep, a faster, more ergonomic alternative to grep.
# Install fd-find, a faster, more ergnonmic alternative to find.
apt --version
if [ $? -eq 0 ]; then
    echo "Found \`apt\` binary. Installing some utilities with \`apt\`."
    sudo apt install ripgrep fd-find
fi

# Install nvm, a node.js version manager.
# https://github.com/nvm-sh/nvm
nvm --version
if [ $? -ne 0 ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
fi

