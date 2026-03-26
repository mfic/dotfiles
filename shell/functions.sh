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
    local d=""
    local limit=$1
    for ((i=1; i <= limit; i++)); do
        d=$d/..
    done
    d=$(echo "$d" | sed 's/^\///')
    if [ -z "$d" ]; then
        d=..
    fi
    cd "$d"
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