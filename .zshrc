# work around bug of Pycharm PATH
# https://youtrack.jetbrains.com/issue/IDEA-176888
[[ "$PATH" =~ /usr/local/bin  ]] || export PATH=/usr/local/bin:$PATH
export PATH="/usr/local/sbin:$PATH"
# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# If a pattern for filename generation has no matches, delete  the
# pattern  from  the  argument list instead of reporting an error.
# Overrides NOMATCH
setopt nullglob

# Enable virtualenvwrapper
[ -e /usr/bin/virtualenvwrapper.sh ] && source /usr/bin/virtualenvwrapper.sh || source /usr/local/bin/virtualenvwrapper.sh

# Enable plugin manager
source "${HOME}/.zgen/zgen.zsh"

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

# if the init scipt doesn't exist
if ! zgen saved; then

  # specify plugins here
  zgen oh-my-zsh
  zgen oh-my-zsh themes/af-magic
  # zgen oh-my-zsh themes/amuse
  zgen oh-my-zsh plugins/git
  zgen oh-my-zsh plugins/docker
  zgen oh-my-zsh plugins/autojump
  zgen oh-my-zsh plugins/colorize
  zgen oh-my-zsh plugins/colored-man-pages
  # sudo Simply hitting ESC twice puts sudo in front of the current command,
  # or the last one if your cli is empty
  zgen oh-my-zsh plugins/sudo
  zgen load zsh-users/zsh-syntax-highlighting
  zgen load zsh-users/zsh-autosuggestions
  # slient virtualenv autoswitch
  export AUTOSWITCH_SILENT=true
  zgen load "MichaelAquilina/zsh-autoswitch-virtualenv"

  # generate the init script from plugins above
  zgen save
fi

# User configuration
eval $(keychain -Q -q --agents ssh --eval ~/.ssh/id_rsa)

export PATH="/Users/dragonkid/Coding/odps/odpscmd/bin:$PATH"
# for java env
export PATH="$HOME/.jenv/bin:$PATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Preferred editor for local and remote sessions
export EDITOR='/usr/bin/vim'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

export LESS=-SRXF
# execute
alias -s tgz='tar -zxvf'
alias -s gz='gunzip'
alias -s zip='unzip'
alias -s bz2='tar -xjvf'
# deal with it laterly on git
suspend() {
    mv "$1"{,.suspend}
}
restore() {
    mv "$1" "${1:0:-8}"
}
alias lssuspend='find . -name "*.suspend"'
# vim
alias vi='vim'
alias viminstall='vim +PluginInstall +qall'
alias vimupdate='vim +PluginUpdate +qall'
# more history
export HISTSIZE=1000000
export HISTFILESIZE=1000000
# colorize code on cat
alias cat='pygmentize -g'
# others
alias zshconfig="vi ~/.zshrc"
alias awk='gawk'
alias sed='gsed'
alias h='history'
alias f='fzf'
alias up='(cd ~/.tmux && git pull) && (cd ~/.vim_runtime && git pull) && (cd ~/.dotfiles && git pull) && brew update && brew upgrade && brew cask outdated | awk -F " " "{print $1}" | xargs brew cask install --force && brew cleanup'
alias burpsuite='jenv shell oracle64-1.8.0.172 && java -jar /Applications/BurpUnlimited/BurpUnlimited.jar'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_CTRL_T_COMMAND='ag -g ""'    # search file ignore files which ignored by .gitignore
eval "$(jenv init -)"

# load private configurations
source ~/.dotfiles/private.sh

