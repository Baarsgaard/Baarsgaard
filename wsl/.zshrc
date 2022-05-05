# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/home/ste/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Uncomment the following line to automatically update without prompting.
DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# Caution: this setting can cause issues with multiline prompts (zsh 5.7.1 and newer seem to work)
# See https://github.com/ohmyzsh/ohmyzsh/issues/5765
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
HIST_STAMPS="yyyy-mm-dd"

# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(
  fzf-tab
  fzf-zsh-plugin
  git
  wd
  terraform
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

#
# User configuration
#

# Custom Prompt
PROMPT='%{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)'
PROMPT+="
%(?:%{$fg[green]%}➜ :%{$fg[red]%}➜ )%{$reset_color%}"


# custom alias
alias ap='ansible-playbook'
alias al='ansible-lint'
alias ai='ansible-galaxy init'
#alias tf='terraform'
alias la='ls -A --group-directories-first'
alias ll='ls -alh --group-directories-first --file-type'
alias l='ls -CF1h --group-directories-first'
alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}'
# --line-number
alias glr='git pull origin "$(git rev-parse --abbrev-ref origin/HEAD | cut -d/ -f 2-)" --rebase'
alias gcm='git commit -m'
alias docker='podman'

set_pass() {
  IFS= read -rs PASS < /dev/tty
}

_wd_path() {
  if [ "$(grep -c "^$2:" ~/.warprc)" -eq 1 ]; then
    wd_path="$(wd path "$2")"
  else
    wd_path="$2"
  fi

  if [[ "$1" =~ '^.*\.exe' ]]; then
    wd_path="$(wslpath -w "$wd_path")"
  fi

  $1 "$wd_path"
}

cw() {
  _wd_path 'code' "${1:-.}"
}

ew() {
  _wd_path 'explorer.exe' "${1:-.}"
}

search() {
  QUERY="$(echo "$@" | tr ' ' '+')"
  powershell.exe -c "start('https://google.com/search?q=$QUERY')"
}

export FZF_DEFAULT_COMMAND="fd --type file --follow --color=always"
export FZF_DEFAULT_OPTS="--ansi"

# target check
target_cmd() {
  case $1 in
  hc)
    CMD="docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}' --filter health=unhealthy"
    ;;

  mem)
    CMD="free -g"
    ;;

  *)
    CMD="$1"
    ;;
  esac

  for i in {1..4}; do
    echo "target $i";
    ssh target$i "$CMD";
  done;
}

# Auto load existing ssh-agent socket
export SSH_AUTH_SOCK="/home/ste/.ssh/agent.sock"
ssh-add -l 2>/dev/null >/dev/null
if [ $? -ge 2 ] && [ -S $SSH_AUTH_SOCK ]; then
  pkill ssh-agent
  rm -rf $SSH_AUTH_SOCK || true
  ssh-agent -s -a $SSH_AUTH_SOCK >/dev/null
fi

export LESSOPEN='| /usr/share/source-highlight/src-hilite-lesspipe.sh %s'
export LESS=' -R '

stty start undef

export PATH="$PATH:/home/ste/.dotnet/"
