#!/bin/bash
SCRIPT=$(readlink -f "$0")
BASEDIR=$(dirname "${SCRIPT}")

# config zsh
## install oh-my-zsh
if [ ! -e ~/.oh-my-zsh ]; then
    wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh
    chsh -s `which zsh`
fi
## install powerlevel9k theme
if [ "$1" == "powerlevel9k" ]; then
    git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

    ## install awesome-terminal-fonts
    git clone https://github.com/gabrielelana/awesome-terminal-fonts.git /tmp/awesome-terminal-fonts
    bash /tmp/awesome-terminal-fonts/install.sh
fi
## install virtualenvwrapper
sudo pip install virtualenvwrapper
## install antigen
curl https://cdn.rawgit.com/zsh-users/antigen/v1.2.4/bin/antigen.zsh > ~/.oh-my-zsh/antigen.zsh
## linking zshrc
ln -sf ${BASEDIR}/.zshrc ~/.zshrc

# config vim
VIM_RUNTIME=~/.vim_runtime
if [ ! -e ${VIM_RUNTIME} ]; then
    git clone https://github.com/dragonkid/vimrc.git ~/.vim_runtime
    sh ~/.vim_runtime/install_awesome_vimrc.sh
else
    cd ${VIM_RUNTIME} && git pull origin master
fi
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

# config tmux
TMUX=~/.tmux
if [ ! -e ${TMUX} ]; then
    git clone https://github.com/dragonkid/tmux-config.git ~/.tmux
    ln -sf ~/.tmux/.tmux.conf ~/.tmux.conf
    ## build tmux-mem-cpu-load
    cd ~/.tmux && git submodule init && git submodule update
    cd ~/.tmux/vendor/tmux-mem-cpu-load && cmake . && make && sudo make install
else
    cd ${TMUX} && git pull origin master
fi

# install .gitconfig
ln -sf ${BASEDIR}/.gitconfig ~/.gitconfig
