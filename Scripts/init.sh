#!/usr/bin/bash


#
# USE ME
# curl -s -L URL_TO_SCRIPT_HERE | bash
#

IFS= read -rs PASS < /dev/tty

echo $PASS | sudo -s apt update
sudo apt upgrade -y

sudo apt install python-software-properties software-properties-common

# GIT
sudo add-apt-repository ppa:git-core/ppa -y

# TF
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com focal main"

sudo apt update
sudo apt upgrade -y

git --version

link() {
  ln -s "$HOME/projects/Raunow/wsl/$1" "$HOME/$1"
}

git clone 'https://github.com/Raunow/Raunow.git' "$HOME/projects/Raunow"

link .zshrc
link .zprofile
link .vimrc
link .gitconfig


sudo apt install zsh fzf 

sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
mkdir -p "$ZSH_CUSTOM"

git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone https://github.com/unixorn/fzf-zsh-plugin.git "$ZSH_CUSTOM/plugins/fzf-zsh-plugin"
git clone https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM/plugins/fzf-tab"

echo $PASS | chsh -s $(which zsh)
