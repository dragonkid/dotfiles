useradd -m -s /bin/bash god
usermod -aG sudo god && echo "god ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >> /home/god/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/god/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

sudo apt install build-essential
brew install gcc tmux zsh tmux-mem-cpu-load bat fzf autojump ncdu lsd keychain jenv diff-so-fancy gnu-sed


BASEDIR=~/.dotfiles
# zsh
## install zgen
git clone https://github.com/tarjoilija/zgen.git ~/.zgen
# config zsh
chsh -s `which zsh`
## install virtualenvwrapper
pip3 install virtualenvwrapper --break-system-packages

ln -sf ${BASEDIR}/zshrc ~/.zshrc

# tmux
git clone --depth 1 https://github.com/dragonkid/tmux-config.git ~/.tmux
ln -sf ~/.tmux/.tmux.conf ~/.tmux.conf
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
## us ctrl + B & I to install plugins

ln -sf ${BASEDIR}/gitconfig ~/.gitconfig
ln -sf ${BASEDIR}/gitignore ~/.gitignore
ln -sf ${BASEDIR}/gitattributes ~/.gitattributes

ln -sf ${BASEDIR}/p10k.zsh ~/.p10k.zsh
