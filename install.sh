#!/bin/bash
set -euo pipefail

BASEDIR=~/.dotfiles
INSTALL_BREW=false
SETUP_HAMMERSPOON=false
SETUP_OPENCLAW=false

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --brew         Install Homebrew and packages from Brewfile (default: skip)
    --hammerspoon  Setup Hammerspoon config (default: skip)
    --openclaw     Setup OpenClaw workspace and skills (default: skip)
    -h, --help     Show this help message

EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --brew)
            INSTALL_BREW=true
            shift
            ;;
        --hammerspoon)
            SETUP_HAMMERSPOON=true
            shift
            ;;
        --openclaw)
            SETUP_OPENCLAW=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

# Retry git operations with exponential backoff
git_with_retry() {
    local max_attempts=5
    local attempt=1
    local delay=2

    while [ $attempt -le $max_attempts ]; do
        if git "$@"; then
            return 0
        fi
        if [ $attempt -lt $max_attempts ]; then
            log_info "Git operation failed (attempt $attempt/$max_attempts), retrying in ${delay}s..."
            sleep $delay
            delay=$((delay * 2))
        fi
        attempt=$((attempt + 1))
    done
    log_error "Git operation failed after $max_attempts attempts"
    return 1
}

trap 'log_error "Failed at line $LINENO"' ERR

# Function to safely link with backup
link_config() {
    local src=$1 dst=$2
    if [ -L "$dst" ]; then
        rm "$dst"
    elif [ -e "$dst" ]; then
        log_info "Backing up $dst"
        mv "$dst" "${dst}.backup.$(date +%Y%m%d)"
    fi
    ln -s "$src" "$dst"
}

# Install Homebrew if needed
if [ "$INSTALL_BREW" = true ]; then
    if ! command -v brew &> /dev/null; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [ -f "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -f "/usr/local/bin/brew" ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        log_success "Homebrew installed"
    else
        log_info "Homebrew already installed"
    fi

    log_info "Installing packages from Brewfile..."
    brew bundle install --file="$BASEDIR/Brewfile"
    log_success "Packages installed"
else
    log_info "Skipping Homebrew installation (use --brew to install)"
fi

# config hammerspoon
if [ "$SETUP_HAMMERSPOON" = true ]; then
    log_info "Configuring Hammerspoon..."
    if [ -d ~/.hammerspoon ]; then
        log_info "Hammerspoon config exists, pulling latest changes..."
        git -C ~/.hammerspoon pull origin master || log_info "Pull failed or no changes"
    else
        git_with_retry clone https://github.com/dragonkid/awesome-hammerspoon.git ~/.hammerspoon
    fi
    log_success "Hammerspoon configured"
else
    log_info "Skipping Hammerspoon setup (use --hammerspoon to enable)"
fi

# config vim
log_info "Configuring Vim..."
VIM_RUNTIME=~/.vim_runtime
if [ ! -e ${VIM_RUNTIME} ]; then
    git_with_retry clone --depth 1 https://github.com/dragonkid/vimrc.git ~/.vim_runtime
    sh ~/.vim_runtime/install_awesome_vimrc.sh
else
    git -C ${VIM_RUNTIME} pull origin master
fi
## add colors
COLORS_DIR=~/.vim/colors/
mkdir -p ${COLORS_DIR} && cp ${BASEDIR}/colors/* ${COLORS_DIR}
## install Vundle & plugins
VUNDLE=~/.vim/bundle/Vundle.vim
if [ ! -e ${VUNDLE} ]; then
    git_with_retry clone --depth 1 https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    vim +PluginInstall +qall
    ## install YouCompleteMe
    cd ~/.vim/bundle/YouCompleteMe/ && python3 install.py --clangd-completer
else
    git -C ${VUNDLE} pull origin master
    vim +PluginUpdate +qall
fi
log_success "Vim configured"

## install zgen
log_info "Installing zgen..."
if [ -d "${HOME}/.zgen" ]; then
    log_info "zgen already installed, pulling latest changes..."
    git -C "${HOME}/.zgen" pull origin master || log_info "Pull failed or no changes"
else
    git_with_retry clone https://github.com/tarjoilija/zgen.git "${HOME}/.zgen"
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

## add project path to PYTHONPATH automatically
mkdir -p ~/.virtualenvs
if ! grep -q "export PYTHONPATH" ~/.virtualenvs/postactivate 2>/dev/null; then
    echo 'export PYTHONPATH=${PYTHONPATH}:`pwd`' >> ~/.virtualenvs/postactivate
    log_info "Added PYTHONPATH to postactivate"
fi

## install ipdb alfter virtualenv is created. `-i` parameter can also be used.
if ! grep -q "pip install ipdb" ~/.virtualenvs/postmkvirtualenv 2>/dev/null; then
    echo '[[ $VIRTUAL_ENV ]] && pip install ipdb' >> ~/.virtualenvs/postmkvirtualenv
    log_info "Added ipdb to postmkvirtualenv"
fi
## linking zshrc
log_info "Linking zshrc..."
link_config "${BASEDIR}/zshrc" ~/.zshrc
log_success "zshrc linked"

# config tmux
log_info "Configuring tmux..."
TMUX=~/.tmux
if [ ! -e ${TMUX} ]; then
    git_with_retry clone --depth 1 https://github.com/dragonkid/tmux-config.git ~/.tmux
    ln -sf ~/.tmux/.tmux.conf ~/.tmux.conf
    ## install tmux plugin manager
    if [ ! -d ~/.tmux/plugins/tpm ]; then
        git_with_retry clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi
else
    git -C ${TMUX} pull origin master
    ln -sf ~/.tmux/.tmux.conf ~/.tmux.conf
    ## install tmux plugin manager if not present
    if [ ! -d ~/.tmux/plugins/tpm ]; then
        git_with_retry clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    else
        git -C ~/.tmux/plugins/tpm pull origin master || log_info "Pull failed or no changes"
    fi
fi
log_success "tmux configured"

# config git
log_info "Linking git config files..."
link_config "${BASEDIR}/gitconfig" ~/.gitconfig
link_config "${BASEDIR}/gitignore" ~/.gitignore
link_config "${BASEDIR}/gitattributes" ~/.gitattributes
# create empty gitconfig.local for machine-specific settings
if [ ! -f ~/.gitconfig.local ]; then
    echo "# Machine-specific git settings (user email, credentials, etc.)" > ~/.gitconfig.local
    log_info "Created ~/.gitconfig.local"
fi
log_success "Git config linked"

# config claude
log_info "Setting up Claude Code..."
# Install mgrep (semantic search tool for Claude Code)
if ! command -v mgrep &> /dev/null; then
    log_info "Installing mgrep..."
    npm install -g @mixedbread/mgrep
    log_success "mgrep installed"
else
    log_info "mgrep already installed"
fi
# Install typescript-language-server (dependency for Claude Code)
if ! command -v typescript-language-server &> /dev/null; then
    log_info "Installing typescript-language-server..."
    npm install -g typescript-language-server
    log_success "typescript-language-server installed"
else
    log_info "typescript-language-server already installed"
fi
# Link Claude Code config files
log_info "Linking Claude Code config..."
mkdir -p ~/.claude
link_config "${BASEDIR}/claude/commands" ~/.claude/commands
link_config "${BASEDIR}/claude/settings.json" ~/.claude/settings.json
link_config "${BASEDIR}/claude/skills" ~/.claude/skills
link_config "${BASEDIR}/claude/rules" ~/.claude/rules
link_config "${BASEDIR}/claude/claude.md" ~/.claude/claude.md
link_config "${BASEDIR}/claude/hooks" ~/.claude/hooks
link_config "${BASEDIR}/claude/scripts" ~/.claude/scripts
link_config "${BASEDIR}/claude/statusline.sh" ~/.claude/statusline.sh
log_success "Claude Code configured"

# config obsidian vault
log_info "Setting up Obsidian vault..."
VAULT_LINK="$HOME/Documents/second-brain"
VAULT_GIT="/usr/local/data/second-brain.git"

# symlink: ~/Documents/second-brain → Google Drive vault
if [ -L "$VAULT_LINK" ] || [ -d "$VAULT_LINK" ]; then
    log_info "Vault symlink already exists, skipping"
else
    VAULT_GDRIVE="$HOME/Google Drive/My Drive/Second Brain"
    while true; do
        if [ -d "$VAULT_GDRIVE" ]; then
            break
        fi
        read -rp "Obsidian vault not found at $VAULT_GDRIVE. Enter vault path (or 'skip'): " input
        if [ "$input" = "skip" ]; then
            VAULT_GDRIVE=""
            break
        fi
        VAULT_GDRIVE="$input"
    done
    if [ -n "$VAULT_GDRIVE" ]; then
        link_config "$VAULT_GDRIVE" "$VAULT_LINK"
        log_success "Vault symlink created"
    else
        log_info "Skipping Obsidian vault setup"
    fi
fi

# separated git dir + .git file
if ([ -d "$VAULT_LINK" ] || [ -L "$VAULT_LINK" ]) && [ ! -d "$VAULT_GIT" ]; then
    VAULT_REMOTE="https://github.com/dragonkid/second-brain.git"
    log_info "Initializing vault git ($VAULT_REMOTE)..."
    sudo mkdir -p /usr/local/data && sudo chown "$USER" /usr/local/data
    # Resolve symlink — git -C through a symlink can't find the .git file
    # created by --separate-git-dir in the resolved target
    VAULT_REAL="$(cd "$VAULT_LINK" && pwd -P)"
    # Clean up stale .git file/dir from a previous failed run
    rm -rf "$VAULT_REAL/.git" "$VAULT_GIT"
    git init --separate-git-dir="$VAULT_GIT" "$VAULT_REAL"
    git -C "$VAULT_REAL" remote add origin "$VAULT_REMOTE"
    git_with_retry -C "$VAULT_REAL" fetch origin
    git -C "$VAULT_REAL" reset origin/main
fi
log_success "Obsidian vault configured"

# config openclaw
if [ "$SETUP_OPENCLAW" = true ]; then
    log_info "Setting up OpenClaw..."
    mkdir -p ~/.openclaw
    if [ -L ~/.openclaw/workspace ]; then
        rm ~/.openclaw/workspace
    fi
    mkdir -p ~/.openclaw/workspace
    for f in "${BASEDIR}"/openclaw/workspace/*.md; do
        link_config "$f" ~/.openclaw/workspace/"$(basename "$f")"
    done
    link_config "${BASEDIR}/openclaw/workspace/.gitignore" ~/.openclaw/workspace/.gitignore
    link_config "${BASEDIR}/openclaw/workspace/skills" ~/.openclaw/workspace/skills
    log_success "OpenClaw configured"
else
    log_info "Skipping OpenClaw setup (use --openclaw to enable)"
fi

# disable macos press and hold
log_info "Disabling macOS press and hold..."
defaults write -g ApplePressAndHoldEnabled -bool false
log_success "macOS press and hold disabled"

log_success "Installation complete!"
