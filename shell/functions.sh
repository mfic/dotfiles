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

# Copy file with a progress bar
cpp() {
    set -e
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
    d=$(echo $d | sed 's/^\///')
    if [ -z "$d" ]; then
        d=..
    fi
    cd $d
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
    ls -v | cat -n | while read n f; do mv -n "${f}" "${1}-${n}.${2}"; done
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