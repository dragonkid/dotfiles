#!/bin/bash
SCRIPT=$(readlink -f "$0")
BASEDIR=$(dirname "${SCRIPT}")

# sudo add-apt-repository ppa:pkg-vim/vim-daily -y
sudo apt-get update
# sudo apt-get install --reinstall vim
sudo apt-get install -y git cmake build-essential keychain autojump python-dev python3-dev
# fix add-apt-repository command not found
which add-apt-repository || sudo apt-get install -y python-software-properties software-properties-common

# install zsh
sudo apt-get install zsh
if [ ! -e ~/.oh-my-zsh ]; then
    wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh
    chsh -s `which zsh`
fi

if [ "$1" == "powerlevel9k" ]; then
    ## install powerlevel9k
    git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

    ## install awesome-terminal-fonts
    git clone https://github.com/gabrielelana/awesome-terminal-fonts.git /tmp/awesome-terminal-fonts
    bash /tmp/awesome-terminal-fonts/install.sh
fi

## install zsh-syntax-highlighting
ZSH_SYNTAX_HIGHLIGHTING=~/.oh-my-zsh/plugins/zsh-syntax-highlighting
if [ ! -e ${ZSH_SYNTAX_HIGHLIGHTING} ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_SYNTAX_HIGHLIGHTING}
else
    cd ${ZSH_SYNTAX_HIGHLIGHTING} && git pull origin master
fi
## linking zshrc
ln -sf ${BASEDIR}/.zshrc ~/.zshrc

# install vimrc
VIM_RUNTIME=~/.vim_runtime
if [ ! -e ${VIM_RUNTIME} ]; then
    git clone git@github.com:dragonkid/vimrc.git ~/.vim_runtime
else
    cd ${VIM_RUNTIME} && git pull origin master
fi
sh ~/.vim_runtime/install_awesome_vimrc.sh
## add colors
COLORS_DIR=~/.vim/colors/
mkdir -p ${COLORS_DIR} && cp ${BASEDIR}/colors/* ${COLORS_DIR}
## install Vundle & plugins
VUNDLE=~/.vim/bundle/Vundle.vim
if [ ! -e ${VUNDLE} ]; then
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    vim +PluginInstall +qall
    ## install YouCompleteMe
    cd ~/.vim/bundle/YouCompleteMe/ && ./install.py --clang-completer --gocode-completer --tern-completer
else
    cd ${VUNDLE} && git pull origin master
    vim +PluginUpdate +qall
fi

# install tmuxrc
TMUX=~/.tmux
if [ ! -e ${TMUX} ]; then
    git clone git@github.com:dragonkid/tmux-config.git ~/.tmux
    ln -sf ~/.tmux/.tmux.conf ~/.tmux.conf
    ## build tmux-mem-cpu-load
    cd ~/.tmux && git submodule init && git submodule update
    cd ~/.tmux/vendor/tmux-mem-cpu-load && cmake . && make && sudo make install
else
    cd ${TMUX} && git pull origin master
fi

# install .gitconfig
ln -sf ${BASEDIR}/.gitconfig ~/.gitconfig
