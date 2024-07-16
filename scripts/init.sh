#!/bin/bash

set -euo pipefail

# Nix
sh <(curl -L https://nixos.org/nix/install) --daemon
nix --version

# Home-Manager
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update

nix-shell '<home-manager>' -A install

home-manager build
home-manager switch
nix-collect-garbage

which zsh | sudo tee -a /etc/shells
chsh -s "$(which zsh)"
