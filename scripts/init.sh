#!/usr/bin/bash

set -eu
set -o pipefail

#
# USE ME
# curl -s -L URL_TO_SCRIPT_HERE | bash
#

sudo pacman -Syu --noconfirm

# Config Repo
mkdir -p "$HOME/projects"
git clone 'https://github.com/Raunow/Raunow.git' "$HOME/projects/Raunow"

overwrite() {
  cp -f "$HOME/projects/Raunow/wsl/$1" "$HOME/$1"
}
overwrite ".zshrc"
overwrite ".zprofile"
overwrite ".vimrc"
overwrite ".gitconfig"

# ZSH
sudo pacman -Sy zsh fzf zsh-syntax-highlighting

# oh-my-zsh
export CHSH='no'
export RUNZSH='no'
export KEEP_ZSHRC='yes'
sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
mkdir -p "$ZSH_CUSTOM"

git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone https://github.com/unixorn/fzf-zsh-plugin.git "$ZSH_CUSTOM/plugins/fzf-zsh-plugin"
git clone https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM/plugins/fzf-tab"

chsh -s $(which zsh)
