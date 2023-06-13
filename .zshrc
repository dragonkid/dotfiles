[ -f ~/.zshrc_private  ] && source $HOME/.zshrc_private

# If a pattern for filename generation has no matches, delete  the
# pattern  from  the  argument list instead of reporting an error.
# Overrides NOMATCH
setopt nullglob
export PATH="~/.cargo/bin:~/go/bin:$PATH"

# Enable virtualenvwrapper
export VIRTUALENVWRAPPER_PYTHON=/opt/homebrew/bin/python
export WORKON_HOME="$HOME/Coding/.virtualenvs"
export VIRTUALENVWRAPPER_HOOK_DIR=$WORKON_HOME
source virtualenvwrapper.sh

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=7

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
#ZSH_CUSTOM=~/.zshrc_private

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

# Enable plugin manager
source "${HOME}/.zgen/zgen.zsh"

# if the init scipt doesn't exist
if ! zgen saved; then

  # specify plugins here
  zgen oh-my-zsh
  zgen oh-my-zsh themes/af-magic
  zgen oh-my-zsh plugins/git
  zgen oh-my-zsh plugins/golang
  zgen oh-my-zsh plugins/fzf
  zgen oh-my-zsh plugins/kubectl
  zgen oh-my-zsh plugins/minikube
  zgen oh-my-zsh plugins/docker
  zgen oh-my-zsh plugins/autojump
  zgen oh-my-zsh plugins/colorize
  zgen oh-my-zsh plugins/colored-man-pages
  zgen load zsh-users/zsh-syntax-highlighting
  zgen load Dabz/kafka-zsh-completions
  zgen load jeffreytse/zsh-vi-mode
  ### Fix slowness of pastes with zsh-syntax-highlighting.zsh
  pasteinit() {
    OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
    zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
  }

  pastefinish() {
    zle -N self-insert $OLD_SELF_INSERT
  }
  zstyle :bracketed-paste-magic paste-init pasteinit
  zstyle :bracketed-paste-magic paste-finish pastefinish
  ### Fix slowness of pastes
  zgen load zsh-users/zsh-syntax-highlighting
  zgen load zsh-users/zsh-autosuggestions
  #zgen load unixorn/autoupdate-zgen
  zgen load "MichaelAquilina/zsh-autoswitch-virtualenv"

  # generate the init script from plugins above
  zgen save
fi


export AUTOSWITCH_SILENT=true
export AUTOSWITCH_DEFAULT_PYTHON=/opt/homebrew/bin/python
export AUTOSWITCH_VIRTUAL_ENV_DIR=$WORKON_HOME
export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# User configuration
[ -z $SSH_AGENT_PID  ] && eval $(keychain -Q -q --agents ssh --eval ~/.ssh/id_rsa)
# Golang speed up
export GOPROXY=https://goproxy.cn

# cursor navigation mapping
bindkey "^[h" backward-word
bindkey "^[l" forward-word

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Preferred editor for local and remote sessions
export EDITOR='/usr/bin/vim'
export LESS=-SRXF
# execute
alias -s tgz='tar -zxvf'
alias -s gz='gunzip'
alias -s tar='tar -xvf'
alias -s zip='unzip'
alias -s bz2='tar -xjvf'
# vim
alias vi='vim'
alias viminstall='vim +PluginInstall +qall'
alias vimupdate='vim +PluginUpdate +qall'
# kubecm
alias kc='kubecm'
# more history
export HISTSIZE=1000000
export HISTFILESIZE=1000000
alias cat='bat'
# others
alias zshconfig="vi ~/.zshrc"
alias du="ncdu --color dark -rr -x --exclude .git --exclude node_modules"
alias help='tldr'
alias fgw="export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890"
# https://github.com/robbyrussell/oh-my-zsh/issues/5349#issuecomment-387210275
alias ls="lsd"
alias awk='gawk'
alias sed='gsed'
alias h='history'
alias up='(cd ~/.tmux && git pull) && (cd ~/.vim_runtime && git pull) && (cd ~/.dotfiles && git pull) && (cd ~/.hammerspoon && git pull) && brew update && brew upgrade && brew cask outdated | awk -F " " "{print $1}" | xargs brew cask install --force && brew cleanup'
alias burpsuite='jenv shell oracle64-1.8.0.172 && java -jar /Applications/BurpUnlimited/BurpUnlimited.jar'

# search file ignore files which ignored by .gitignore
export FZF_CTRL_T_COMMAND="ag -g \"\""
export FZF_CTRL_T_OPTS="--preview 'bat --color \"always\" {}'"
autoload -U compinit; compinit
[[ ! -f ~/.kubecm ]] || source ~/.kubecm

# the fuck
eval $(thefuck --alias)

# gpt-comrade
alias comrade='gpt-comrade "$@" -k="$(fc -ln -1)"'
