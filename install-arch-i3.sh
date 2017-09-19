#!/bin/bash
SCRIPT="$(cd "$(dirname "$0")" && pwd -P)"/"$(basename "$0")"
BASEDIR=$(dirname "${SCRIPT}")

sudo pacman -Syu && sudo pacman -Sy base-devel zsh git tmux htop wget bmon keychain lsof terminator autojump

# config vim
VIM_RUNTIME=~/.vim_runtime
if [ ! -e ${VIM_RUNTIME} ]; then
    git clone --depth 1 https://github.com/dragonkid/vimrc.git ~/.vim_runtime
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
    git clone --depth 1 https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    vim +PluginInstall +qall
    ## install YouCompleteMe
    cd ~/.vim/bundle/YouCompleteMe/ && ./install.py --clang-completer --gocode-completer --tern-completer
else
    cd ${VUNDLE} && git pull origin master
    vim +PluginUpdate +qall
fi

# config zsh
## install oh-my-zsh
if [ ! -e ~/.oh-my-zsh ]; then
    wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh
    chsh -s `which zsh`
fi
## install powerlevel9k theme
if [ "$1" == "powerlevel9k" ]; then
    git clone --depth 1 https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

    ## install awesome-terminal-fonts
    git clone --depth 1 https://github.com/gabrielelana/awesome-terminal-fonts.git /tmp/awesome-terminal-fonts
    bash /tmp/awesome-terminal-fonts/install.sh
fi
## install virtualenvwrapper
sudo pip install virtualenvwrapper
## add project path to PYTHONPATH automatically
echo 'export PYTHONPATH=${PYTHONPATH}:`pwd`' >> ~/.virtualenvs/postactivate
## install antigen
curl -L git.io/antigen > ~/.oh-my-zsh/antigen.zsh
## linking zshrc
ZSHRC=~/.zshrc
if [ -f ${ZSHRC} ]; then
    echo -ne "\n\033[0;31m${ZSHRC} existed. 'force' to replace it by force, 'merge' to merge them with vimdiff(f/M):\033[0m"
    read choice
    [ "${choice}" == "f" ] && ln -sf ${BASEDIR}/.zshrc ${ZSHRC} || vimdiff ${BASEDIR}/.zshrc ${ZSHRC}
fi

# config tmux
TMUX=~/.tmux
if [ ! -e ${TMUX} ]; then
    git clone --depth 1 https://github.com/dragonkid/tmux-config.git ~/.tmux
    ln -sf ~/.tmux/.tmux.conf ~/.tmux.conf
    ## install tmux plugin manager
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ## build tmux-mem-cpu-load
    cd ~/.tmux && git submodule init && git submodule update
    cd ~/.tmux/vendor/tmux-mem-cpu-load && cmake . && make && sudo make install
else
    cd ${TMUX} && git pull origin master
fi

# install .gitconfig
ln -sf ${BASEDIR}/.gitconfig ~/.gitconfig

# config Xmodmpa(swap ctrl & capslock and swap alt & super)
ln -sf ${BASEDIR}/arch-i3/.Xmodmap .Xmodmap

# config i3
ln -sf ${BASEDIR}/arch-i3/i3-config ~/.i3/config

# config terminator
ln -sf ${BASEDIR}/arch-i3/terminator-config ~/.config/terminator/config

# config yaourt
ln -sf ${BASEDIR}/arch-i3/yoaurtrc ~/.yaourtrc
