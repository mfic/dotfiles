# dotfiles

Cross-platform dotfiles for Linux (Debian/Ubuntu, Arch) and Windows. Supports server (bash-only) and workstation (zsh + extras) profiles.

## Quick Start

### Linux

```bash
git clone https://github.com/mfic/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Server (bash only — lightweight)
./install.sh server

# Workstation (zsh + Oh My Zsh + plugins)
./install.sh workstation
```

### Windows

```powershell
git clone https://github.com/mfic/dotfiles.git $env:USERPROFILE\.dotfiles
cd $env:USERPROFILE\.dotfiles\windows
.\setup.ps1
```

## What gets installed

### Server profile (`./install.sh server`)

| Symlink | Target |
|---------|--------|
| `~/.bashrc` | `shell/bashrc` |
| `~/.bash_profile` | `shell/bash_profile` |
| `~/.vimrc` | `vim/vimrc` |
| `~/.config/nvim/init.vim` | `nvim/init.vim` |
| `~/.gitconfig` | generated (includes `git/gitconfig` + user identity) |
| `~/.tmux.conf` | `tmux/tmux.conf` |
| `~/bin/*` | `bin/*` (utility scripts) |

Plus vim-plug and plugins are auto-installed for both vim and neovim.

### Workstation profile (`./install.sh workstation`)

Everything from server, plus:

| Symlink | Target |
|---------|--------|
| `~/.zshrc` | `shell/zshrc` |

Also installs: zsh, Oh My Zsh, zsh-autosuggestions, zsh-syntax-highlighting.

### Windows (`windows/setup.ps1`)

- Links PowerShell profile with oh-my-posh prompt
- Links `_vimrc` and neovim config
- Installs oh-my-posh if missing

## Structure

```
dotfiles/
├── install.sh                  # Linux bootstrap
├── shell/
│   ├── exports.sh              # Shared env vars (PATH, EDITOR, HISTSIZE, colors)
│   ├── aliases.sh              # Shared aliases (navigation, docker, disk, etc.)
│   ├── functions.sh            # Shared functions (extract, ftext, up, encodeb64, etc.)
│   ├── bashrc                  # Bash config (prompt with CPU/network stats)
│   ├── bash_profile            # Login shell -> sources bashrc
│   └── zshrc                   # Zsh + Oh My Zsh (vi keybindings, kubeconfig merging)
├── vim/
│   └── vimrc                   # vim-plug, NERDTree, line numbers, syntax
├── nvim/
│   └── init.vim                # Sources shared vimrc
├── tmux/
│   └── tmux.conf               # Ctrl-A prefix, vim pane nav, clipboard integration
├── git/
│   └── gitconfig               # Defaults with colors (no user block)
├── bin/
│   ├── k8s-delete-stuck-namespaces  # Fix terminating K8s namespaces
│   ├── mergepdf                     # Merge PDFs via ghostscript
│   └── convertdocx2pdf             # Batch DOCX to PDF via pandoc
└── windows/
    ├── Microsoft.PowerShell_profile.ps1
    └── setup.ps1               # Windows bootstrap
```

## Per-machine overrides

Create `~/.local_profile` for machine-specific settings (not tracked by git):

```bash
# Example ~/.local_profile
export PATH="$HOME/go/bin:$PATH"
alias k='kubectl'
```

Both `bashrc` and `zshrc` source this file automatically.

## Git user config

`install.sh` prompts for your name and email during setup. It generates a `~/.gitconfig` that:
1. Includes the shared config from `git/gitconfig` (aliases, colors, defaults)
2. Sets your `[user]` block per-machine

On re-run, it shows the current values as defaults — just press Enter to keep them.

## Using with Ansible

The `mfic.dotfiles` Ansible role clones this repo and runs `install.sh`:

```yaml
roles:
  - role: mfic.dotfiles
    vars:
      dotfiles_profile: server  # or workstation
```

## Key aliases

| Alias | Command |
|-------|---------|
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
