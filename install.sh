# Insall Starship.rs, which provides a nice command line prompt.
# https://starship.rs/
curl -sS https://starship.rs/install.sh | sh

sc=`which apt`
if [ $sc -eq 0 ]; then
    echo "Found \`apt\` binary. Installing some utilities with \`apt\`."
    # Install ripgrep, a faster, more ergonomic alternative to grep.
    # Install fd-find, a faster, more ergnonmic alternative to find.
    sudo apt install ripgrep fd-find
fi

