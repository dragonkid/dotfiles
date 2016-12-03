# Prepare

## Ubuntu

upgrade vim

```
sudo add-apt-repository ppa:pkg-vim/vim-daily -y
sudo apt-get install --reinstall vim
```

if there is no `add-apt-repository`

```
sudo apt-get install -y python-software-properties software-properties-common
```

install zsh

```
sudo apt-get install zsh
```

install tmux

```
sudo apt-get install tmux
```

other deps

```
sudo apt-get install -y cmake build-essential keychain autojump python-dev python3-dev
```

# Installation

```
./install.sh or ./install powerlevel9k
```
