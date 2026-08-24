#!/usr/bin/env bash
# Shared functions — sourced by both bash and zsh

# Extracts any archive(s)
extract () {
    for archive in "$@"; do
        if [ -f "$archive" ]; then
            case "$archive" in
                *.tar.bz2)   tar xvjf "$archive"    ;;
                *.tar.gz)    tar xvzf "$archive"    ;;
                *.bz2)       bunzip2 "$archive"     ;;
                *.rar)       rar x "$archive"       ;;
                *.gz)        gunzip "$archive"      ;;
                *.tar)       tar xvf "$archive"     ;;
                *.tbz2)      tar xvjf "$archive"    ;;
                *.tgz)       tar xvzf "$archive"    ;;
                *.zip)       unzip "$archive"       ;;
                *.Z)         uncompress "$archive"  ;;
                *.7z)        7z x "$archive"        ;;
                *)           echo "don't know how to extract '$archive'..." ;;
            esac
        else
            echo "'$archive' is not a valid file!"
        fi
    done
}

# Recursive grep with color
ftext () {
    grep -iIHrn --color=always "$1" . | less -r
}

# Copy file with a progress bar (requires strace)
cpp() {
    if ! command -v strace &>/dev/null; then
        echo "cpp: strace not found" >&2; return 1
    fi
    strace -q -ewrite cp -- "${1}" "${2}" 2>&1 \
    | awk '{
        count += $NF
        if (count % 10 == 0) {
            percent = count / total_size * 100
            printf "%3d%% [", percent
            for (i=0;i<=percent;i++)
                printf "="
            printf ">"
            for (i=percent;i<100;i++)
                printf " "
            printf "]\r"
        }
    }
    END { print "" }' total_size=$(stat -c '%s' "${1}") count=0
}

# Copy and go to the directory
cpg () {
    if [ -d "$2" ]; then
        cp "$1" "$2" && cd "$2"
    else
        cp "$1" "$2"
    fi
}

# Move and go to the directory
mvg () {
    if [ -d "$2" ]; then
        mv "$1" "$2" && cd "$2"
    else
        mv "$1" "$2"
    fi
}

# Create and go to the directory
mkdirg () {
    mkdir -p "$1"
    cd "$1"
}

# Goes up a specified number of directories (i.e. up 4)
up () {
    if [[ -z "$1" || "$1" -lt 1 ]]; then
        echo "Usage: up <number>" >&2
        return 1
    fi
    local d="" limit=$1
    for ((i=1; i <= limit; i++)); do
        d=$d/..
    done
    cd "${d#/}"
}

# Returns the last 2 fields of the working directory
pwdtail () {
    pwd | awk -F/ '{nlast = NF -1; print $nlast"/"$NF}'
}

# IP address lookup
whatsmyip () {
    echo -n "Internal IP: "
    ip -4 addr show scope global | grep inet | awk '{print $2}' | head -1
    echo -n "External IP: "
    curl -s https://ifconfig.me
    echo
}
alias whatismyip="whatsmyip"

# Trim leading and trailing spaces
trim() {
    local var=$@
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

# Rename files sequentially: rename-all-sequentially <prefix> <extension>
rename-all-sequentially() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: rename-all-sequentially <prefix> <extension>"
        return 1
    fi
    local i=1
    for f in *; do
        [ -f "$f" ] || continue
        mv -n "$f" "${1}-${i}.${2}"
        (( i++ ))
    done
}

# Base64 encode (copies to clipboard if xclip/pbcopy available)
encodeb64() {
    local encoded
    encoded=$(echo -n "$1" | base64)
    echo "$encoded"
    if command -v pbcopy &>/dev/null; then
        echo -n "$encoded" | pbcopy
    elif command -v xclip &>/dev/null; then
        echo -n "$encoded" | xclip -selection clipboard
    fi
}

# Helper functions to run Docker containers
run-ollama() {
  if docker ps -a --format '{{.Names}}' | grep -Fxq ollama; then
    docker start ollama >/dev/null
  else
    docker run -d \
      --name ollama \
      --restart unless-stopped \
      -v ollama:/root/.ollama \
      -p 127.0.0.1:11434:11434 \
      ollama/ollama >/dev/null
  fi
}
## Ollama CLI helper
ollama() {
  docker start ollama >/dev/null 2>&1
  docker exec -it ollama ollama "$@"
}

# Reload shell configuration
dotfiles-reload() {
    if [ -n "$ZSH_VERSION" ]; then
        source "$HOME/.zshrc"
    else
        source "$HOME/.bashrc"
    fi
}
alias dfr='dotfiles-reload'

# Update dotfiles repo and re-run the install script
dotfiles-update() {
    local dir="${DOTFILES:-$HOME/dotfiles}"
    if [ ! -d "$dir" ]; then
        echo "Dotfiles directory not found: $dir"
        return 1
    fi

    local changes
    changes=$(git -C "$dir" status --porcelain)
    if [ -n "$changes" ]; then
        echo "[info] Uncommitted changes in $dir:"
        git -C "$dir" status --short
        echo "[info] Commit or stash your changes before updating."
        return 1
    fi

    local profile
    if [ -n "${1:-}" ]; then
        profile="$1"
        echo "[info] Using profile: $profile"
    elif [ -f "$HOME/.dotfiles_profile" ]; then
        profile=$(cat "$HOME/.dotfiles_profile")
        echo "[info] Using saved profile: $profile"
    else
        profile="server"
        echo "[info] No saved profile found, defaulting to: $profile"
    fi

    echo "[info] Updating dotfiles in $dir..."
    git -C "$dir" pull || return 1
    bash "$dir/install.sh" "$profile" --skip-git
}
alias dfu='dotfiles-update'

# Verify that every managed config is still a symlink into the dotfiles repo.
#
# Worth running after `omarchy update`, and especially after `omarchy refresh
# <app>` or `omarchy reinstall configs`: those back up and *copy* a fresh
# default into place, which silently replaces the symlink with a real file. The
# config keeps working, so nothing complains — it has just stopped being shared
# between machines.
dotfiles-check() {
    local dir="${DOTFILES:-$HOME/dotfiles}"
    local cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
    local ok=0 detached=0 missing=0

    if [ ! -d "$dir" ]; then
        echo "Dotfiles directory not found: $dir"
        return 1
    fi

    local links=(
        "$HOME/.bashrc:$dir/shell/bashrc"
        "$HOME/.bash_profile:$dir/shell/bash_profile"
        "$HOME/.vimrc:$dir/vim/vimrc"
    )

    if [ -r /usr/share/omarchy/default/bash/env-bootstrap ]; then
        local host
        host="$(cat /etc/hostname 2>/dev/null | tr -d '[:space:]')"
        links+=(
            "$cfg/hypr/bindings.lua:$dir/omarchy/config/hypr/bindings.lua"
            "$cfg/hypr/autostart.lua:$dir/omarchy/config/hypr/autostart.lua"
            "$cfg/hypr/monitors.lua:$dir/omarchy/config/hypr/monitors.lua"
            "$cfg/hypr/hosts/$host.lua:$dir/omarchy/config/hypr/hosts/$host.lua"
            "$cfg/omarchy/shell.json:$dir/omarchy/config/omarchy/shell.json"
            "$cfg/alacritty/alacritty.toml:$dir/omarchy/config/alacritty/alacritty.toml"
            "$cfg/tmux/tmux.conf:$dir/omarchy/config/tmux/tmux.conf"
            "$cfg/nvim/lua/config/options.lua:$dir/omarchy/config/nvim/lua/config/options.lua"
            "$cfg/nvim/lua/config/keymaps.lua:$dir/omarchy/config/nvim/lua/config/keymaps.lua"
        )
    else
        links+=(
            "$cfg/nvim/init.vim:$dir/nvim/init.vim"
            "$HOME/.tmux.conf:$dir/tmux/tmux.conf"
        )
    fi

    [ -f "$HOME/.dotfiles_profile" ] && \
        [ "$(cat "$HOME/.dotfiles_profile")" = "workstation" ] && \
        links+=("$HOME/.zshrc:$dir/shell/zshrc")

    local entry dest want actual
    for entry in "${links[@]}"; do
        dest="${entry%%:*}"
        want="${entry#*:}"
        if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
            echo "[missing]  $dest"
            missing=$((missing + 1))
        elif [ ! -L "$dest" ]; then
            echo "[detached] $dest is a real file, not a link to ${want#$dir/}"
            detached=$((detached + 1))
        else
            actual="$(readlink -f "$dest" 2>/dev/null)"
            if [ "$actual" != "$(readlink -f "$want" 2>/dev/null)" ]; then
                echo "[wrong]    $dest -> $actual"
                detached=$((detached + 1))
            else
                ok=$((ok + 1))
            fi
        fi
    done

    echo ""
    echo "[info] $ok linked, $detached detached, $missing missing"
    if [ "$detached" -gt 0 ]; then
        echo "[info] Re-run install.sh to relink (existing files are backed up first)."
        return 1
    fi
    return 0
}
alias dfcheck='dotfiles-check'

# Remove all timestamped dotfiles backup files
dotfiles-clean-backups() {
    local found=0
    while IFS= read -r -d '' f; do
        echo "Removing $f"
        rm -f "$f"
        found=1
    done < <(find "$HOME" -maxdepth 4 -name '*.bak.[0-9]*' -print0 2>/dev/null)
    [ "$found" -eq 0 ] && echo "[info] No backup files found."
}
alias dfclean='dotfiles-clean-backups'

run-it-tools() {
  if docker ps -a --format '{{.Names}}' | grep -Fxq it-tools; then
    docker start it-tools >/dev/null
  else
    docker run -d \
      --name it-tools \
      --restart unless-stopped \
      -p 127.0.0.1:8080:80 \
      corentinth/it-tools:latest >/dev/null
  fi
}