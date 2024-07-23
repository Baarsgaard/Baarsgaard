#!/bin/bash

# Nix
curl -fsSL https://nixos.org/nix/install | sh -s -- --daemon --yes

nix_src_path='/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
if [ -e "$nix_src_path" ]; then
  # shellcheck disable=SC1090
  . "$nix_src_path"
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

which zsh | sudo tee -a /etc/shells
chsh -s "$(which zsh)"

echo 'Source nix variables using below command or login again'
echo ". '$nix_src_path'"
