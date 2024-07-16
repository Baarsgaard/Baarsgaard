{ config, pkgs, ... }:

{
  nixpkgs = {
    overlays = [
      (import (builtins.fetchTarball {
        url = "https://github.com/helix-editor/helix/archive/master.tar.gz";
      }))
    ];
    config.allowUnfree = true;
  };

  home.username = "ste";
  home.homeDirectory = "/home/${config.home.username}";
  home.stateVersion = "24.05"; # Do not touch

  home.packages = [
    pkgs.ansible
    pkgs.containerd
    pkgs.docker-buildx
    pkgs.docker-compose
    pkgs.docker_27
    pkgs.jq
    pkgs.kind
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.lychee
    pkgs.terraform
    pkgs.typos
    pkgs.unzip
    pkgs.vault
    pkgs.wslu
    pkgs.yq-go
    pkgs.zsh-fzf-tab

    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  home.sessionVariables = {
    BROWSER = "wslview";
    COLORTERM = "truecolor";
    DISABLE_UPDATE_PROMPT = "true";
    EDITOR = "hx";
    MANPAGER = "bat -l man -p";
    SSH_AUTH_SOCK="${config.home.homeDirectory}/.ssh/agent.sock";
  };
  home.sessionPath = ["${config.home.homeDirectory}/.local/bin"];

  services = {
    home-manager.autoUpgrade = {
      enable = true;
      frequency = "weekly";
    };
    ssh-agent.enable = true;
    syncthing.enable = true;
  };

  # Let Home Manager install and manage itself.
  programs = {
    bun.enable = true;
    fd.enable = true;
    home-manager.enable = true;
    ripgrep.enable = true;
    bat.enable = true;
    go.enable = false;
  };

  programs.ssh = {
    addKeysToAgent = "yes";
    compression = true;
    controlMaster = "auto";
    controlPath = "~/.ssh/.sock-%C";
    controlPersist = "10m";
    enable = true;
    hashKnownHosts = false;
    includes = ["~/.config.d/*"];
    serverAliveCountMax = 3;
    serverAliveInterval = 5;

    extraOptionOverrides = {
      ConnectTimeout = "5";
      StrictHostkeyChecking = "yes";
      IdentitiesOnly = "yes";
    };

    matchBlocks = {
      server = {
        user = "ste";
        hostname = "remote.steff.tech";
      };
      kindle = {
        user = "root";
        identityFile = "~/.ssh/kindle";
        hostname = "192.168.15.244";
        extraOptions = {
          StrictHostkeyChecking = "no";
          UserKnownHostsFile = "/dev/null";
        };
      };
    };
  };

  programs.zsh = {
    enable = true;

    initExtra = ''
      PROMPT="%{$fg[cyan]%}%c%{$reset_color%} "'$(git_prompt_info)'"
      %(?:%{$fg[green]%}:%{$fg[red]%})> %{$reset_color%}"
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
    '';
    history = {
      size = 20000;
      extended = true;
    };
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        # "ansible"
        # "bun"
        # "fluxcd"
        "fzf"
        "git"
        "kubectl"
        # "ripgrep"
        # "rust"
        # "terraform"
        "wd"
      ];
    };
    shellAliases = {
      grep = "grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.vscode}";
      la = "ls -A --group-directories-first";
      ll = "ls -CF1h --group-directories-first";
      l = "ls -alh --group-directories-first --file-type";

      # Ansible
      agr = "ansible-galaxy install -r requirements.yml";
      al = "ansible-lint";
      ap = "ansible-playbook";
      av = "ansible-vault";

      # GIT
      gcm  = "git commit -m";
      glp  = "git branch --merged next | grep -v '^[ *]*next$' | xargs git branch -d";
      glr  = "git pull origin \"$(git rev-parse --abbrev-ref --short origin/HEAD)\" --rebase";
      grp  = "git remote update origin --prune";
      gstv = "git status -vv";

      # Difftastic
      # gd   = "GIT_EXTERNAL_DIFF=difft git diff";
      # glgp = "GIT_EXTERNAL_DIFF=difft git log --stat --patch --ext-diff";
      # gsh  = "GIT_EXTERNAL_DIFF=difft git show HEAD --ext-diff";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    historyWidgetOptions = ["+s" "+m" "-x"];
  };

  programs.git = {
    enable = true;
    userName = "ste";
    userEmail = "steff.bpoulsen@gmail.com";

    extraConfig = {
      core = {
        editor = "hx";
        excludesfile = "~/.gitignore";
        hooksPath = "~/.githooks";
        autocrlf = "input";
        fileMode = false;
      };
      gpg.format = "ssh";
      merge.conflictstyle = "diff3";
      http.sslverify = true;
      pull.rebase = true;
      push.default = "current";
      rebase.autosquash = true;
    };
    signing = {
      key = "~/.ssh/signing_ed25519";
      signByDefault = true;
    };

    difftastic.enable = false;
    delta = {
      enable = true;
      options = {
        navigate = true;
        features = "decorations";
      };
    };
  };

  programs.helix = {
    enable = true;
    package = pkgs.helix;
    defaultEditor = true;
    settings = {
      theme = "onedark";
      editor = {
        line-number = "relative";
        mouse = false;
        shell = ["bash" "-c"];
        auto-format = true;
        file-picker.hidden = false;
        lsp = {
          display-messages = true;
          display-inlay-hints = true;
          snippets = true;
        };
        indent-guides = {
          render = true;
          character = "╎";
          skip-levels = 0;
        };
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
      };
      keys.normal."+" = {
        b = ":pipe base64 -d";
        j = [":pipe jq" ":set-language json" "collapse_selection"];
        s = ["split_selection_on_newline" ":sort" "keep_primary_selection" "collapse_selection"];
        # v = ":sh ansible-vault decrypt Ctrl+%" # Waiting for 3134
      };
    };
    languages = {
      language-server = {
        ruff-lsp = {
          command = "ruff-lsp";
        };
        rust-analyzer.config = {
          checkOnSave = true;
          check.command = "clippy";
        };
        taplo.config.formatting = {
          align_entries = true;
          reorder_keys = true;
          trailing_newline = true;
        };
        terraform-ls.config = {
          indexing.ignoreDirectoryNames = [".helix" ".vscode" ".idea"];
          ignoreSingleFileWarning = true;
          experimentalFeatures.prefillRequiredFields = true;
        };
        yaml-language-server.config.yaml = {
          completion = true;
          format.enable = true;
          hover = true;
          validation = true;
          schemas = {
            "https://json.schemastore.org/github-workflow.json" = [".github/workflows/*.y*ml"];
          };
        };
      };
      language = [
        {
          name = "rust";
          auto-format = true;
          debugger = {
            name = "codelldb";
            command = "codelldb";
            port-arg = "--port {}";
            transport = "tcp";
            templates = [{
              name = "binary";
              request = "launch";
              completion = [{ completion = "filename"; name = "binary"; }];
              args.program = "{0}";
              args.runInTerminal = true;
            }];
          };
        }
        {
          name = "markdown";
          language-servers = ["markdown-oxide"];
        }
        {
          name = "python";
          language-servers = ["ruff-lsp"];
        }
        {
          name = "bash";
          formatter = {
            command = "shfmt";
            args = ["-i" "2"];
          };
        }
        {
          name = "toml";
          formatter = {
            command = "taplo";
            args = ["format" "-"];
          };
        }
        {
          name = "yaml";
          language-servers = ["yaml-language-server" "ansible-language-server"];
        }
      ];
    };
    extraPackages = [
      pkgs.ansible-language-server
      pkgs.bash-language-server
      pkgs.dockerfile-language-server-nodejs
      pkgs.gopls
      pkgs.helix-gpt # TODO https://github.com/leona/helix-gpt
      pkgs.helm-ls
      pkgs.markdown-oxide
      pkgs.nil
      pkgs.nodePackages.vscode-json-languageserver
      pkgs.ruff
      pkgs.rustup
      pkgs.shellcheck
      pkgs.shfmt
      pkgs.taplo
      pkgs.terraform-ls
      pkgs.yaml-language-server
    ];
  };
}
