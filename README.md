# dotfiles

Cross-platform dotfiles for Linux (Debian/Ubuntu, Arch) and Windows. Supports server (bash-only) and workstation (zsh + extras) profiles.

## Quick Start

### Linux

```bash
git clone https://github.com/mfic/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Server (bash only — lightweight)
./install.sh server

# Workstation (zsh + Oh My Zsh + plugins)
./install.sh workstation
```

The chosen profile is saved to `~/.dotfiles_profile` so future updates restore it automatically.

### Windows

```powershell
git clone https://github.com/mfic/dotfiles.git $env:USERPROFILE\dotfiles
cd $env:USERPROFILE\dotfiles\windows
.\setup.ps1
```

> **Tip:** Enable Developer Mode in *Settings → System → For Developers* to allow symlinks without admin rights. Without it, files are copied instead of linked and won't stay in sync automatically.

## What gets installed

### Linux — Server profile (`./install.sh server`)

| Symlink | Target |
|---------|--------|
| `~/.bashrc` | `shell/bashrc` |
| `~/.bash_profile` | `shell/bash_profile` |
| `~/.vimrc` | `vim/vimrc` |
| `~/.config/nvim/init.vim` | `nvim/init.vim` |
| `~/.tmux.conf` | `tmux/tmux.conf` |
| `~/bin/*` | `bin/*` (utility scripts) |
| `~/.gitconfig` | generated — includes `git/gitconfig` + user identity |

vim-plug and plugins are auto-installed for both vim and neovim.

### Linux — Workstation profile (`./install.sh workstation`)

Everything from server, plus:

| Symlink | Target |
|---------|--------|
| `~/.zshrc` | `shell/zshrc` |

Also installs: zsh, Oh My Zsh, zsh-autosuggestions, zsh-syntax-highlighting.

### Windows (`windows/setup.ps1`)

| File | Target |
|------|--------|
| PowerShell profile (PS5 + PS7) | `windows/Microsoft.PowerShell_profile.ps1` |
| `~/_vimrc` | `vim/vimrc` |
| `%LOCALAPPDATA%\nvim\init.vim` | `nvim/init.vim` |
| `~/.gitconfig` | generated — includes `git/gitconfig` + user identity |

Also installs: oh-my-posh, FiraCode Nerd Font, vim-plug and plugins.

## Dotfiles management commands

These are available in every shell after install:

| Command | Alias | Description |
|---------|-------|-------------|
| `dotfiles-update` | `dfu` | Pull latest changes and re-run install (skips git config prompt) |
| `dotfiles-reload` | `dfr` | Reload shell config without restarting the terminal |
| `dotfiles-clean-backups` | `dfclean` | Remove all timestamped `.bak.*` backup files |

### `dfu` — update dotfiles

```bash
dfu              # uses saved profile from ~/.dotfiles_profile
dfu workstation  # override profile for this run
```

`dfu` will **abort** if there are uncommitted local changes, showing a `git status` so you can review and commit first.

### `install.sh` flags

```bash
./install.sh [server|workstation] [--skip-git] [--help]
```

| Flag | Description |
|------|-------------|
| `server` / `workstation` | Profile to install (default: `server`) |
| `--skip-git` | Skip the interactive git user name/email prompt |
| `--help` | Show usage |

### `setup.ps1` flags (Windows)

```powershell
.\setup.ps1 [-SkipGit]
```

## Structure

```
dotfiles/
├── install.sh                  # Linux bootstrap
├── shell/
│   ├── exports.sh              # Shared env vars (PATH, EDITOR, HISTSIZE, colors)
│   ├── aliases.sh              # Shared aliases (navigation, docker, disk, etc.)
│   ├── functions.sh            # Shared functions (extract, ftext, up, encodeb64, etc.)
│   ├── bashrc                  # Bash config (prompt with CPU/network stats)
│   ├── bash_profile            # Login shell — sources bashrc
│   └── zshrc                   # Zsh + Oh My Zsh (vi keybindings, kubeconfig merging)
├── vim/
│   └── vimrc                   # vim-plug, NERDTree, line numbers, syntax
├── nvim/
│   └── init.vim                # Sources shared vimrc
├── tmux/
│   └── tmux.conf               # Ctrl-A prefix, vim pane nav, clipboard integration
├── git/
│   └── gitconfig               # Shared git config (colors, aliases — no user block)
├── bin/
│   ├── k8s-delete-stuck-namespaces  # Fix terminating K8s namespaces
│   ├── mergepdf                     # Merge PDFs via ghostscript
│   └── convertdocx2pdf             # Batch DOCX to PDF via pandoc
└── windows/
    ├── Microsoft.PowerShell_profile.ps1
    └── setup.ps1               # Windows bootstrap
```

## Per-machine overrides

Create a local override file for machine-specific settings (not tracked by git):

| Platform | File |
|----------|------|
| Linux / WSL | `~/.local_profile` |
| Windows | `~/local_profile.ps1` |

```bash
# Example ~/.local_profile
export PATH="$HOME/go/bin:$PATH"
alias k='kubectl'
```

Both `bashrc` and `zshrc` source this file automatically.

## Git user config

`install.sh` and `setup.ps1` prompt for your name and email at install time. They write a `~/.gitconfig` that:

1. Includes the shared config from `git/gitconfig` (aliases, colors, defaults)
2. Sets your `[user]` block per-machine

On re-run, current values are shown as defaults — press Enter to keep them. When updating via `dfu`, the git prompt is skipped automatically (`--skip-git`).

## Backups

Before overwriting any existing config file, a timestamped backup is created:

```
~/.bashrc.bak.20250327143012
```

At the end of install you are offered the option to delete them. At any time, run `dfclean` (Linux) or `dfclean` (Windows PowerShell) to clean up all backup files.

## Docker helpers

| Function | Description |
|----------|-------------|
| `run-ollama` | Start Ollama container (creates it on first run) |
| `ollama <args>` | Run ollama CLI via Docker |
| `run-it-tools` | Start IT-Tools container at `http://localhost:8080` |

## Key aliases

| Alias | Command |
|-------|---------|
| `dfu` | Update dotfiles |
| `dfr` | Reload shell config |
| `dfclean` | Clean backup files |
| `dc` | `docker compose` |
| `dcu` | `docker compose up -d` |
| `dcd` | `docker compose down` |
| `dcl` | `docker compose logs -f` |
| `dcdu` | down + up |
| `dps` | `docker ps` |
| `ll` | `ls -alF` |
| `la` | `ls -Alh` |
| `..` | `cd ..` |
| `...` | `cd ../..` |

## Tmux

- **Prefix**: `Ctrl-A` (instead of default `Ctrl-B`)
- **Pane navigation**: `h/j/k/l` (vim-style)
- **Split**: `s` vertical, `v` horizontal
- **Copy mode**: `Escape` to enter, `v` to select, `y` to yank (xclip on Linux, pbcopy on macOS)
- **Reload config**: `prefix + r`
- **Mouse**: enabled

## Vim features

- **vim-plug** — auto-installs on first run
- **NERDTree** — toggle with `Ctrl+n`
- **vim-airline** — status line
- **vim-sensible** — Tim Pope's sensible defaults
- Line numbers + relative numbers
- Smart case search
- Mouse support
- `jj` to escape insert mode

## Zsh plugins

ansible, docker, docker-compose, extract, git, helm, kubectl, sudo, tmux, zsh-autosuggestions, zsh-syntax-highlighting

## Kubernetes

- Zsh auto-merges kubeconfigs from `~/.kube/config` and `~/.kube/k8s/*.yml`
- `k8s-delete-stuck-namespaces` utility in `~/bin/`

## Using with Ansible

The `mfic.dotfiles` Ansible role clones this repo and runs `install.sh`:

```yaml
roles:
  - role: mfic.dotfiles
    vars:
      dotfiles_profile: server  # or workstation
```
