# NOTE: This script must be run from the dotfiles/ root to work!
ln -nfs `pwd`/.bashrc ~/.bashrc
ln -nfs `pwd`/.bash_aliases ~/.bash_aliases
ln -nfs `pwd`/.config/starship.toml ~/.config/starship.toml
ln -nfs `pwd`/.config/nvim/init.vim ~/.config/nvim/init.vim
ln -nfs `pwd`/.local/bin/* ~/.local/bin/
