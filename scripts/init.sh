#!/usr/bin/bash

#
# USE ME
# curl -s -L https://raw.githubusercontent.com/Baarsgaard/Baarsgaard/master/scripts/init.sh | bash
#

set -eu
set -o pipefail

sudo apt update
sudo apt upgrade -y
sudo apt install zsh fzf wslu ripgrep shellcheck shfmt unzip gpg syncthing jq ansible \
  docker-cd docker-ce-cli docker-compose-plugin containerd.io docker-buildx-plugin

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup component add rust-analyzer

cargo install git-delta
cargo install bat
cargo install taplo-cli --features lsp
cargo install lychee
cargo install --git https://github.com/Feel-ix-343/markdown-oxide.git markdown-oxide
cargo install --git https://github.com/astral-sh/ruff.git ruff
cargo install typos-cli
cargo install cargo-workspaces
cargo install --locked cargo-autoinherit

mkdir -p "$HOME/projects"
cd "$HOME/projects"
git clone https://github.com/helix-editor/helix
cd helix
cargo install --locked --path helix-term

mkdir -p "$HOME/.config/helix"
ln -Ts "$PWD/runtime" "$HOME/.config/helix/runtime"
cd "$HOME"

mkdir -p "$HOME/.local/bin"
curl -fsSL https://bun.sh/install | bash
ln -Ts "$(which bun)" ~/.local/bin/node

bun i -g \
  dockerfile-language-server-nodejs \
  vscode-langservers-extracted \
  sql-language-server \
  yaml-language-server@next \
  @ansible/ansible-language-server \
  bash-language-server

# oh-my-zsh
export CHSH='no'
export RUNZSH='no'
export KEEP_ZSHRC='yes'
export ZSH_CUSTOM='~/.oh-my-zsh/custom'
mkdir -p "$ZSH_CUSTOM"

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone https://github.com/unixorn/fzf-zsh-plugin.git "$ZSH_CUSTOM/plugins/fzf-zsh-plugin"
git clone https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM/plugins/fzf-tab"

chsh -s $(which zsh)

# Dotfiles
git clone 'https://github.com/Baarsgaard/Baarsgaard.git' "$HOME/projects/Baarsgaard"

# overwrite() {
#   cp -f "$HOME/projects/Baarsgaard/wsl/$1" "$HOME/$1"
# }
# overwrite ".zshrc"
# overwrite ".zprofile"
# overwrite ".vimrc"
# overwrite ".gitconfig"
