#!/bin/bash
SCRIPT="$(cd "$(dirname "$0")" && pwd -P)"/"$(basename "$0")"
BASEDIR=$(dirname "${SCRIPT}")

sudo pacman -Syu && sudo pacman -Sy base-devel zsh git tmux htop wget bmon keychain lsof terminator autojump blueman

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
    ## install YouCompleteMe(libtinfo5 may be needed)
    cd ~/.vim/bundle/YouCompleteMe/ && ./install.py --clang-completer --gocode-completer --tern-completer
else
    cd ${VUNDLE} && git pull origin master
    vim +PluginUpdate +qall
fi


# config zsh
chsh -s `which zsh`
## install zgen
git clone https://github.com/tarjoilija/zgen.git "${HOME}/.zgen"
## install virtualenvwrapper
sudo pip install virtualenvwrapper
## add project path to PYTHONPATH automatically
echo 'export PYTHONPATH=${PYTHONPATH}:`pwd`' >> ~/.virtualenvs/postactivate
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
ln -sf ${BASEDIR}/arch-i3/.i3 ~/.i3

# config terminator
ln -sf ${BASEDIR}/arch-i3/terminator-config ~/.config/terminator/config

# config yaourt
ln -sf ${BASEDIR}/arch-i3/yoaurtrc ~/.yaourtrc

# config xinitrc
ln -sf ${BASEDIR}/arch-i3/xinitrc ~/.xinitrc

# config jupyter notebook
JUPYTER_CONFIG_PATH=~/.jupyter
mkdir -p ${JUPYTER_CONFIG_PATH}
ln -sf ${BASEDIR}/jupyter_notebook_config.py ~/${JUPYTER_CONFIG_PATH}/jupyter_notebook_config.py
