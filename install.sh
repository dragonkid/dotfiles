#!/bin/bash
BASEDIR=~/.dotfiles

#apt-get update && apt-get install cmake build-essential python2.7-dev -y
brew install zsh tmux-mem-cpu-load lsd jenv keychain bat fzf thefuck autojump ncdu tmux font-monofur-nerd-font hammerspoon

# config hammerspoon
git clone https://github.com/dragonkid/awesome-hammerspoon.git ~/.hammerspoon

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
    # cd ~/.vim/bundle/YouCompleteMe/ && ./install.py --clang-completer --gocode-completer --tern-completer
else
    cd ${VUNDLE} && git pull origin master
    vim +PluginUpdate +qall
fi

## install zgen
git clone https://github.com/tarjoilija/zgen.git "${HOME}/.zgen"
# config zsh
chsh -s `which zsh`
## install virtualenvwrapper
sudo pip3 install virtualenvwrapper
## add project path to PYTHONPATH automatically
echo 'export PYTHONPATH=${PYTHONPATH}:`pwd`' >> ~/.virtualenvs/postactivate
## install ipdb alfter virtualenv is created. `-i` parameter can also be used.
echo '[[ $VIRTUAL_ENV ]] && pip install ipdb' >> ~/.virtualenvs/postmkvirtualenv
## linking zshrc
ZSHRC=~/.zshrc
if [ -f ${ZSHRC} ]; then
    echo -ne "\n\033[0;31m${ZSHRC} existed. 'force' to replace it by force, 'merge' to merge them with vimdiff(f/M):\033[0m"
    read choice
    [ "${choice}" == "f" ] && ln -sf ${BASEDIR}/.zshrc ${ZSHRC} || vimdiff ${BASEDIR}/.zshrc ${ZSHRC}
else
    ln -sf ${BASEDIR}/.zshrc ${ZSHRC}
fi

# config tmux
TMUX=~/.tmux
if [ ! -e ${TMUX} ]; then
    git clone --depth 1 https://github.com/dragonkid/tmux-config.git ~/.tmux
    ln -sf ~/.tmux/.tmux.conf ~/.tmux.conf
    ## install tmux plugin manager
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
    cd ${TMUX} && git pull origin master
fi

# config git
ln -sf ${BASEDIR}/gitconfig ~/.gitconfig
ln -sf ${BASEDIR}/gitignore ~/.gitignore
ln -sf ${BASEDIR}/gitattributes ~/.gitattributes

# config jupyter notebook
# JUPYTER_CONFIG_PATH=~/.jupyter
# mkdir -p ${JUPYTER_CONFIG_PATH}
# ln -sf ${BASEDIR}/jupyter_notebook_config.py ~/${JUPYTER_CONFIG_PATH}/jupyter_notebook_config.py

# disable macos press and hold
defaults write -g ApplePressAndHoldEnabled -bool false
