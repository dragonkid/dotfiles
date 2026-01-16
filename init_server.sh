#!/bin/bash
set -euo pipefail

BASEDIR=~/.dotfiles

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

trap 'log_error "Failed at line $LINENO"' ERR

# Function to safely link with backup
link_config() {
    local src=$1 dst=$2
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        log_info "Backing up $dst"
        mv "$dst" "${dst}.backup.$(date +%Y%m%d)"
    fi
    ln -sf "$src" "$dst"
}

# Create god user if needed
log_info "Setting up god user..."
if ! id -u god &>/dev/null; then
    useradd -m -s /bin/bash god
    usermod -aG sudo god
    if ! grep -q "god ALL=(ALL) NOPASSWD:ALL" /etc/sudoers 2>/dev/null; then
        echo "god ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    fi
    log_success "User god created"
else
    log_info "User god already exists"
fi

# Install Homebrew if needed
log_info "Installing Homebrew..."
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add to bashrc if not present
    if ! grep -q "/home/linuxbrew/.linuxbrew/bin/brew shellenv" /home/god/.bashrc 2>/dev/null; then
        echo >> /home/god/.bashrc
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/god/.bashrc
    fi
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    log_success "Homebrew installed"
else
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true
    log_info "Homebrew already installed"
fi

# Install build essentials
log_info "Installing build essentials..."
sudo apt install -y build-essential
log_success "Build essentials installed"

# Use Brewfile for package installation
log_info "Installing packages from Brewfile..."
brew bundle install --file="$BASEDIR/Brewfile"
log_success "Packages installed"

# zsh
## install zgen
log_info "Installing zgen..."
if [ -d ~/.zgen ]; then
    log_info "zgen already installed, pulling latest changes..."
    git -C ~/.zgen pull origin master || log_info "Pull failed or no changes"
else
    git clone https://github.com/tarjoilija/zgen.git ~/.zgen
fi
log_success "zgen installed"

# config zsh
log_info "Configuring zsh..."
if [ "$(basename "$SHELL")" != "zsh" ]; then
    zsh_path=$(which zsh)
    grep -q "^$zsh_path$" /etc/shells 2>/dev/null || echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
    chsh -s "$zsh_path"
    log_info "Shell changed to zsh (restart terminal to use)"
else
    log_info "Shell already set to zsh"
fi

## install virtualenvwrapper
log_info "Installing virtualenvwrapper..."
pip3 install --user virtualenvwrapper --break-system-packages
log_success "virtualenvwrapper installed"

## linking zshrc
log_info "Linking zshrc..."
link_config "${BASEDIR}/zshrc" ~/.zshrc
log_success "zshrc linked"

# tmux
log_info "Configuring tmux..."
if [ ! -e ~/.tmux ]; then
    git clone --depth 1 https://github.com/dragonkid/tmux-config.git ~/.tmux
    ln -sf ~/.tmux/.tmux.conf ~/.tmux.conf
    ## install tmux plugin manager
    if [ ! -d ~/.tmux/plugins/tpm ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi
else
    git -C ~/.tmux pull origin master
    ln -sf ~/.tmux/.tmux.conf ~/.tmux.conf
    ## install tmux plugin manager if not present
    if [ ! -d ~/.tmux/plugins/tpm ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    else
        git -C ~/.tmux/plugins/tpm pull origin master || log_info "Pull failed or no changes"
    fi
fi
log_success "tmux configured (use ctrl + B & I to install plugins)"

# config git
log_info "Linking git config files..."
link_config "${BASEDIR}/gitconfig" ~/.gitconfig
link_config "${BASEDIR}/gitignore" ~/.gitignore
link_config "${BASEDIR}/gitattributes" ~/.gitattributes
log_success "Git config linked"

# config p10k
log_info "Linking p10k config..."
link_config "${BASEDIR}/p10k.zsh" ~/.p10k.zsh
log_success "p10k config linked"

log_success "Server initialization complete!"
