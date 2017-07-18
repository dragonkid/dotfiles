# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# If a pattern for filename generation has no matches, delete  the
# pattern  from  the  argument list instead of reporting an error.
# Overrides NOMATCH
setopt nullglob

# Enable plugin manager
source $ZSH/antigen.zsh

# Enable virtualenvwrapper
[ -e /usr/bin/virtualenvwrapper.sh ] && source /usr/bin/virtualenvwrapper.sh || source /usr/local/bin/virtualenvwrapper.sh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.

## powerlevel9k/powerlevel9k
#ZSH_THEME="powerlevel9k/powerlevel9k"
#POWERLEVEL9K_MODE='awesome-fontconfig'
#POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
#POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status virtualenv time)
#POWERLEVEL9K_VIRTUALENV_BACKGROUND="yellow"
#POWERLEVEL9K_TIME_FORMAT="%D{\uf017 %H:%M:%S \uf073 %Y.%m.%d}"
#POWERLEVEL9K_STATUS_VERBOSE=false
#POWERLEVEL9K_PROMPT_ON_NEWLINE=true

# ZSH_THEME="amuse"

ZSH_THEME="af-magic"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

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
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
antigen bundle dragonkid/zsh-autoswitch-virtualenv
export AUTOSWITCH_SILENT=true
antigen bundle zsh-users/zsh-syntax-highlighting

antigen apply

# sudo Simply hitting ESC twice puts sudo in front of the current command, or the last one if your cli is empty
plugins=(git autojump colored-man-pages redis-cli sudo vagrant)

eval $(keychain -Q -q --agents ssh --eval ~/.ssh/id_rsa)

source $ZSH/oh-my-zsh.sh

# User configuration

export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

export EDITOR='vim'
# execute
alias -s tgz='tar -zxvf'
alias -s gz='gunzip'
alias -s zip='unzip'
alias -s bz2='tar -xjvf'
# vim
alias viminstall='vim +PluginInstall +qall'
alias vimupdate='vim +PluginUpdate +qall'
# more history
export HISTSIZE=1000000
export HISTFILESIZE=1000000
# others
alias h='history'
