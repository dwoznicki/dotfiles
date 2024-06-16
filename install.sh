case "`uname`" in
    Darwin) OSNAME="macos" ;;
    *Linux*) OSNAME="linux" ;;
    *) echo "Unsupported OS: `uname`"; exit 1 ;;
esac
if [ $OSNAME == "macos" ]; then
    brew --version
    if [ $? -ne 0 ]; then
        echo "Installing homebrew." 
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [ $? -ne 0 ]; then
            exit 1
        fi
        (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    brew --version
    if [ $? -ne 0 ]; then
        echo "Unable to find homebrew." >&2
        exit 1
    fi
    brew install neovim fd ripgrep
elif [ $OSNAME == "linux" ]; then
    # Install the following packages:
    # - ripgrep: grep alternative
    # - fd-find: find alternative
    # - xclip: access the system clipboard from the command line
    # - curl: standard network tool
    # - flameshot: a better screenshot program
    apt --version
    if [ $? -eq 0 ]; then
        echo "Found \`apt\` binary. Installing some utilities with \`apt\`."
        sudo apt install ripgrep fd-find xclip curl flameshot
        echo "Installing additional dependencies."
        sudo apt install gcc g++ build-essential
    fi
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
