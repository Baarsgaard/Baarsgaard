#!/bin/bash

set -euo pipefail
read -s -p "Password: " PW

# Nix
curl -fsSL https://nixos.org/nix/install | sh -s -- --daemon --yes
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
nix --version

# Home-Manager
mkdir -p ~/.config/home-manager
curl -fsSL https://raw.githubusercontent.com/Baarsgaard/Baarsgaard/master/dotfiles/home.nix > ~/.config/home-manager/home.nix

nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

home-manager build
home-manager switch
nix-collect-garbage

echo $PW | sudo echo 'tmp'>/dev/null
which zsh | sudo tee -a /etc/shells
echo $PW | chsh -s "$(which zsh)"
