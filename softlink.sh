# NOTE: This script must be run from the dotfiles/ root to work!
case "`uname`" in
    Darwin) OSNAME="macos" ;;
    *Linux*) OSNAME="linux" ;;
    *) echo "Unsupported OS: `uname`"; exit 1 ;;
esac
if [ $OSNAME == "linux" ]; then
    ln -nfs `pwd`/.bashrc ~/.bashrc
    ln -nfs `pwd`/.bash_aliases ~/.bash_aliases
    ln -nfs `pwd`/.inputrc ~/.inputrc
fi
ln -nfs `pwd`/.config/starship.toml ~/.config/starship.toml
mkdir -p ~/.config/nvim/
ln -nfs `pwd`/.config/nvim/init.lua ~/.config/nvim/init.lua
mkdir -p ~/.config/wezterm/
ln -nfs `pwd`/.config/wezterm/* ~/.config/wezterm/
mkdir -p ~/.local/bin/
ln -nfs `pwd`/.local/bin/* ~/.local/bin/
ln -nfs `pwd`/.lscolors.sh ~/.lscolors.sh
ln -nfs `pwd`/.zshrc ~/.zshrc
# Claude Code global config. Only curated, hand-authored files are tracked;
# runtime state (history, sessions, cache, ...) stays machine-local.
mkdir -p ~/.claude/
ln -nfs `pwd`/.claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -nfs `pwd`/.claude/settings.json ~/.claude/settings.json
# Directory links: remove a pre-existing real/empty dir so the link isn't
# nested inside it (harmless if it doesn't exist).
for d in agents skills; do
    [ -L ~/.claude/$d ] || rmdir ~/.claude/$d 2>/dev/null
    ln -nfs `pwd`/.claude/$d ~/.claude/$d
done
