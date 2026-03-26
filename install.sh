#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE="server"
SKIP_GIT=false

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --skip-git) SKIP_GIT=true ;;
        workstation|server) PROFILE="$arg" ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${CYAN}[info]${NC} $*"; }
ok()   { echo -e "${GREEN}[ok]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[error]${NC} $*"; }

# OS detection
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian) echo "debian" ;;
            arch|manjaro)  echo "arch" ;;
            *)             echo "linux" ;;
        esac
    elif [[ "$(uname -s)" == MINGW* ]] || [[ "$(uname -s)" == MSYS* ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Backup tracking
BACKUPS=()

# Symlink helper — backs up existing files with timestamp before linking
link_file() {
    local src="$1" dst="$2"
    if [ -L "$dst" ]; then
        rm -f "$dst"
    elif [ -e "$dst" ]; then
        local backup="${dst}.bak.$(date +%Y%m%d%H%M%S)"
        warn "Backing up $dst -> $backup"
        mv "$dst" "$backup"
        BACKUPS+=("$backup")
    fi
    ln -sf "$src" "$dst"
    ok "Linked $dst"
}

OS=$(detect_os)
info "Detected OS: $OS"
info "Profile: $PROFILE"
echo ""

# Shared config (all profiles)
info "Setting up shared configuration..."
link_file "$DOTFILES_DIR/shell/bashrc" "$HOME/.bashrc"
link_file "$DOTFILES_DIR/shell/bash_profile" "$HOME/.bash_profile"
link_file "$DOTFILES_DIR/vim/vimrc" "$HOME/.vimrc"

# Git config — generate ~/.gitconfig with include + user identity
setup_git() {
    echo ""
    info "Setting up git configuration..."

    local current_name current_email
    current_name="$(git config --global user.name 2>/dev/null || true)"
    current_email="$(git config --global user.email 2>/dev/null || true)"

    local git_name git_email

    if [ -n "$current_name" ]; then
        read -rp "Git user name [$current_name]: " git_name
        git_name="${git_name:-$current_name}"
    else
        read -rp "Git user name: " git_name
        while [ -z "$git_name" ]; do
            read -rp "Git user name (required): " git_name
        done
    fi

    if [ -n "$current_email" ]; then
        read -rp "Git user email [$current_email]: " git_email
        git_email="${git_email:-$current_email}"
    else
        read -rp "Git user email: " git_email
        while [ -z "$git_email" ]; do
            read -rp "Git user email (required): " git_email
        done
    fi

    # Back up existing gitconfig
    if [ -L "$HOME/.gitconfig" ]; then
        rm -f "$HOME/.gitconfig"
    elif [ -e "$HOME/.gitconfig" ]; then
        local backup="$HOME/.gitconfig.bak.$(date +%Y%m%d%H%M%S)"
        warn "Backing up $HOME/.gitconfig -> $backup"
        mv "$HOME/.gitconfig" "$backup"
        BACKUPS+=("$backup")
    fi

    # Generate ~/.gitconfig with include and user block
    cat > "$HOME/.gitconfig" <<GITEOF
[include]
    path = $DOTFILES_DIR/git/gitconfig
[user]
    name = $git_name
    email = $git_email
GITEOF

    ok "Git configured as: $git_name <$git_email>"
}

if [ "$SKIP_GIT" = true ]; then
    info "Skipping git configuration (--skip-git)"
else
    setup_git
fi

# Neovim
mkdir -p "$HOME/.config/nvim"
link_file "$DOTFILES_DIR/nvim/init.vim" "$HOME/.config/nvim/init.vim"

# Tmux
link_file "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"

# Bin scripts
if [ -d "$DOTFILES_DIR/bin" ]; then
    mkdir -p "$HOME/bin"
    for script in "$DOTFILES_DIR/bin"/*; do
        [ -f "$script" ] && link_file "$script" "$HOME/bin/$(basename "$script")"
    done
fi

# Workstation profile additions
if [ "$PROFILE" = "workstation" ]; then
    echo ""
    info "Setting up workstation profile..."

    # Install zsh if missing
    if ! command -v zsh &>/dev/null; then
        info "Installing zsh..."
        case "$OS" in
            debian) sudo apt-get update && sudo apt-get install -y zsh ;;
            arch)   sudo pacman -S --noconfirm zsh ;;
            *)      warn "Cannot auto-install zsh on $OS — install manually" ;;
        esac
    fi

    # Install Oh My Zsh if missing
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        ok "Oh My Zsh installed"
    fi

    # Install zsh plugins
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi

    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi

    link_file "$DOTFILES_DIR/shell/zshrc" "$HOME/.zshrc"
fi

# Install vim-plug for vim
echo ""
info "Setting up vim-plug..."
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
    curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    ok "vim-plug installed for vim"
else
    ok "vim-plug already installed for vim"
fi

# Install vim-plug for neovim
NVIM_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site"
if [ ! -f "$NVIM_DATA/autoload/plug.vim" ]; then
    curl -fLo "$NVIM_DATA/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    ok "vim-plug installed for neovim"
else
    ok "vim-plug already installed for neovim"
fi

# Install vim plugins headless
info "Installing vim plugins..."
if command -v vim &>/dev/null; then
    vim +PlugInstall +qall 2>/dev/null || true
    ok "Vim plugins installed"
fi
if command -v nvim &>/dev/null; then
    nvim +PlugInstall +qall 2>/dev/null || true
    ok "Neovim plugins installed"
fi

echo "$PROFILE" > "$HOME/.dotfiles_profile"

echo ""
ok "Dotfiles setup complete ($PROFILE profile)"
echo ""
info "Per-machine overrides: create ~/.local_profile"

# Offer to clean up backup files
if [ ${#BACKUPS[@]} -gt 0 ]; then
    echo ""
    warn "The following backup files were created:"
    for b in "${BACKUPS[@]}"; do
        warn "  $b"
    done
    read -rp "Delete backup files? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        for b in "${BACKUPS[@]}"; do
            rm -f "$b"
        done
        ok "Backup files deleted"
    fi
fi
