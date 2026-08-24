#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE="server"
SKIP_GIT=false
SKIP_OMARCHY=false

USAGE="Usage: $0 [workstation|server] [--skip-git] [--skip-omarchy]

Profiles control how much shell tooling is installed. The Omarchy desktop
layer is a separate axis: it is applied automatically when this machine is
running Omarchy, and skipped everywhere else."

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --skip-git) SKIP_GIT=true ;;
        --skip-omarchy) SKIP_OMARCHY=true ;;
        workstation|server) PROFILE="$arg" ;;
        --help|-h) echo "$USAGE"; exit 0 ;;
        *) echo "Unknown argument: $arg"; echo "$USAGE"; exit 1 ;;
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

# Omarchy detection — a runtime file test, never an $ID guess, so this stays
# correct on Arch machines that are not Omarchy and on Ubuntu workstations.
OMARCHY=false
if [ -d /usr/share/omarchy ] && [ -r /usr/share/omarchy/default/bash/env-bootstrap ]; then
    if [ "$SKIP_OMARCHY" = true ]; then
        info "Omarchy detected but skipped (--skip-omarchy)"
    else
        OMARCHY=true
    fi
fi

OS=$(detect_os)
info "Detected OS: $OS"
info "Profile: $PROFILE"
[ "$OMARCHY" = true ] && info "Desktop layer: omarchy"
echo ""

# Shared config (all profiles)
info "Setting up shared configuration..."
link_file "$DOTFILES_DIR/shell/bashrc" "$HOME/.bashrc"
link_file "$DOTFILES_DIR/shell/bash_profile" "$HOME/.bash_profile"
link_file "$DOTFILES_DIR/vim/vimrc" "$HOME/.vimrc"

# Git config — generate ~/.gitconfig with include + user identity
setup_git() {
    if [ ! -t 0 ]; then
        warn "Non-interactive shell — skipping git setup"
        return
    fi

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

    # Target the XDG config explicitly rather than relying on `--global`, whose
    # destination depends on which of the two files already exists. Writing with
    # --file preserves everything already in there — notably a [commit] gpgsign
    # block and any 1Password op-ssh-sign program path.
    local git_cfg="${XDG_CONFIG_HOME:-$HOME/.config}/git/config"
    mkdir -p "$(dirname "$git_cfg")"
    touch "$git_cfg"

    # ~/.gitconfig takes precedence over the XDG file, so a leftover one would
    # shadow what we are about to write. Back it up and remove it.
    if [ -L "$HOME/.gitconfig" ]; then
        rm -f "$HOME/.gitconfig"
    elif [ -e "$HOME/.gitconfig" ]; then
        local backup="$HOME/.gitconfig.bak.$(date +%Y%m%d%H%M%S)"
        warn "Backing up $HOME/.gitconfig -> $backup"
        mv "$HOME/.gitconfig" "$backup"
        BACKUPS+=("$backup")
    fi

    git config --file "$git_cfg" user.name  "$git_name"
    git config --file "$git_cfg" user.email "$git_email"

    # The include must come FIRST. Git applies config in file order, so an
    # include appended at the end would let the shared repo config override
    # this machine's own settings — backwards. Placing it at the top makes
    # git/gitconfig the defaults and everything below it the local override.
    #
    # The marker block is removed and rewritten on every run, so re-running is
    # idempotent instead of stacking a new include each time.
    sed -i '/^# >>> dotfiles shared config >>>$/,/^# <<< dotfiles shared config <<<$/d' "$git_cfg"

    # Safety net for a config written by an older version of this script, which
    # appended an unmarked include at the end of the file.
    git config --file "$git_cfg" --unset-all include.path \
        "^$(printf '%s' "$DOTFILES_DIR/git/gitconfig" | sed 's/[].[\*^$\\/]/\\&/g')$" 2>/dev/null || true
    if ! git config --file "$git_cfg" --get-all include.path >/dev/null 2>&1; then
        sed -i '/^\[include\]$/d' "$git_cfg"
    fi

    # Drop leading blank lines so re-runs do not accumulate them.
    sed -i '/./,$!d' "$git_cfg"

    local git_tmp="$git_cfg.tmp.$$"
    {
        echo "# >>> dotfiles shared config >>>"
        echo "# Managed by install.sh. Settings below this block override it."
        echo "[include]"
        echo "	path = $DOTFILES_DIR/git/gitconfig"
        echo "# <<< dotfiles shared config <<<"
        echo ""
        cat "$git_cfg"
    } > "$git_tmp"
    mv "$git_tmp" "$git_cfg"

    if git config --file "$git_cfg" --get commit.gpgsign >/dev/null 2>&1; then
        ok "Preserved existing commit signing configuration"
    fi

    ok "Git configured as: $git_name <$git_email> ($git_cfg)"
}

if [ "$SKIP_GIT" = true ]; then
    info "Skipping git configuration (--skip-git)"
else
    setup_git
fi

# Neovim
# Skipped on Omarchy: it ships LazyVim at ~/.config/nvim/init.lua, and Neovim
# aborts with "E5422: Conflicting configs" when init.lua and init.vim coexist.
# The omarchy layer overlays LazyVim's own lua/config/ files instead.
if [ "$OMARCHY" = false ]; then
    mkdir -p "$HOME/.config/nvim"
    link_file "$DOTFILES_DIR/nvim/init.vim" "$HOME/.config/nvim/init.vim"
fi

# Tmux
# Skipped on Omarchy: tmux loads ~/.tmux.conf AND $XDG_CONFIG_HOME/tmux/tmux.conf,
# XDG last, so Omarchy's config silently wins every conflicting setting (prefix
# included) and you get a half-applied hybrid. The omarchy layer tracks the XDG
# file directly.
if [ "$OMARCHY" = false ]; then
    link_file "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
fi

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
if ! command -v vim &>/dev/null; then
    info "vim not installed — skipping vim-plug for vim"
elif [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
    curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    ok "vim-plug installed for vim"
else
    ok "vim-plug already installed for vim"
fi

# Install vim-plug for neovim.
# Skipped on Omarchy, where Neovim is LazyVim and manages plugins with
# lazy.nvim — vim-plug would be dead weight next to it.
NVIM_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site"
if [ "$OMARCHY" = true ]; then
    info "Omarchy Neovim is LazyVim — skipping vim-plug for neovim"
elif [ ! -f "$NVIM_DATA/autoload/plug.vim" ]; then
    curl -fLo "$NVIM_DATA/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    ok "vim-plug installed for neovim"
else
    ok "vim-plug already installed for neovim"
fi

# Install vim plugins headless
info "Installing vim plugins..."
if command -v vim &>/dev/null; then
    if vim +PlugInstall +qall 2>/dev/null; then
        ok "Vim plugins installed"
    else
        warn "Vim plugin install may have failed — run ':PlugInstall' manually"
    fi
fi
if [ "$OMARCHY" = false ] && command -v nvim &>/dev/null; then
    if nvim +PlugInstall +qall 2>/dev/null; then
        ok "Neovim plugins installed"
    else
        warn "Neovim plugin install may have failed — run ':PlugInstall' manually"
    fi
fi

# Omarchy desktop layer — Arch + Hyprland + Omarchy shell only.
if [ "$OMARCHY" = true ]; then
    echo ""
    info "Setting up Omarchy desktop layer..."
    OMARCHY_SRC="$DOTFILES_DIR/omarchy/config"

    mkdir -p "$HOME/.config/hypr/hosts" "$HOME/.config/omarchy" \
             "$HOME/.config/alacritty" "$HOME/.config/tmux" \
             "$HOME/.config/nvim/lua/config"

    # Hyprland — personal overrides only. hyprland.lua, input.lua and
    # looknfeel.lua are deliberately left as Omarchy ships them, so package
    # updates can keep improving them.
    link_file "$OMARCHY_SRC/hypr/bindings.lua"  "$HOME/.config/hypr/bindings.lua"
    link_file "$OMARCHY_SRC/hypr/autostart.lua" "$HOME/.config/hypr/autostart.lua"
    link_file "$OMARCHY_SRC/hypr/monitors.lua"  "$HOME/.config/hypr/monitors.lua"

    # Per-machine monitor layout, dispatched from monitors.lua by hostname.
    HOSTNAME_SHORT="$(cat /etc/hostname 2>/dev/null | tr -d '[:space:]')"
    if [ -f "$OMARCHY_SRC/hypr/hosts/$HOSTNAME_SHORT.lua" ]; then
        link_file "$OMARCHY_SRC/hypr/hosts/$HOSTNAME_SHORT.lua" \
                  "$HOME/.config/hypr/hosts/$HOSTNAME_SHORT.lua"
    else
        warn "No monitor config for host '$HOSTNAME_SHORT' — using Hyprland autodetect."
        warn "  Add one at omarchy/config/hypr/hosts/$HOSTNAME_SHORT.lua"
    fi

    link_file "$OMARCHY_SRC/omarchy/shell.json"       "$HOME/.config/omarchy/shell.json"
    link_file "$OMARCHY_SRC/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
    link_file "$OMARCHY_SRC/tmux/tmux.conf"           "$HOME/.config/tmux/tmux.conf"

    # Neovim: overlay LazyVim's own user files. Nothing under lua/plugins/ is
    # touched, so Omarchy's theme-hotreload and all-themes specs stay put.
    link_file "$OMARCHY_SRC/nvim/lua/config/options.lua" "$HOME/.config/nvim/lua/config/options.lua"
    link_file "$OMARCHY_SRC/nvim/lua/config/keymaps.lua" "$HOME/.config/nvim/lua/config/keymaps.lua"

    # Validate the Hyprland config rather than trusting the reload.
    if command -v hyprctl &>/dev/null && hyprctl version &>/dev/null; then
        hyprctl reload >/dev/null 2>&1
        errors="$(hyprctl configerrors 2>/dev/null)"
        if [ -z "$errors" ] || [ "$errors" = "no errors" ]; then
            ok "Hyprland reloaded with no config errors"
        else
            err "Hyprland reported config errors:"
            echo "$errors"
        fi
    else
        info "Hyprland not running — config will apply at next login"
    fi

    command -v omarchy-restart-tmux &>/dev/null && omarchy-restart-tmux >/dev/null 2>&1
    ok "Omarchy desktop layer linked"
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
    if [ -t 0 ]; then
        read -rp "Delete backup files? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            for b in "${BACKUPS[@]}"; do
                rm -f "$b"
            done
            ok "Backup files deleted"
        fi
    else
        info "Run 'dfclean' to remove backup files."
    fi
fi
