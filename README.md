# dotfiles

Cross-platform dotfiles for Linux (Debian/Ubuntu, Arch) and Windows. Supports server (bash-only) and workstation (zsh + extras) profiles, plus an Omarchy desktop layer that is applied only on machines actually running Omarchy.

## Two independent axes

The **profile** decides how much shell tooling gets installed. The **desktop layer** is separate: it is detected at runtime and applied only where it belongs, so the same command is correct on every machine.

| Machine | Command | Result |
|---------|---------|--------|
| Omarchy laptop | `./install.sh workstation` | shell + zsh + **Omarchy layer** |
| Ubuntu workstation | `./install.sh workstation` | shell + zsh, no desktop layer |
| Servers | `./install.sh server` | shell only |

Detection is a file test (`/usr/share/omarchy/default/bash/env-bootstrap`), never a guess based on `$ID`, so a plain Arch box that is not Omarchy is treated like any other Linux machine. Force it off with `--skip-omarchy`.

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

**If a change from another machine has not shown up on Windows**, this is almost
always why. With copies, `git pull` alone changes nothing — the copy in your
profile is a snapshot from install time. Run `dfu` (which pulls *and* re-runs
`setup.ps1`) rather than pulling by hand.

The two editors behave differently here, which makes for a quick diagnosis:

| Editor | Reads | Picks up a pull without re-running setup? |
|--------|-------|-------------------------------------------|
| nvim | `init.vim`, which sources `vim/vimrc` **from the repo** | yes |
| vim | `~/_vimrc` — the linked *or copied* file | only if symlinked |

So if something works in nvim but not vim on Windows, you are on copies and
need `dfu`.

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
| `~/.config/git/config` | generated — includes `git/gitconfig` + user identity |

vim-plug and plugins are auto-installed for both vim and neovim.

On Omarchy, `~/.bashrc`, `~/.config/nvim/init.vim` and `~/.tmux.conf` are handled differently — see the desktop layer below.

### Linux — Workstation profile (`./install.sh workstation`)

Everything from server, plus:

| Symlink | Target |
|---------|--------|
| `~/.zshrc` | `shell/zshrc` |

Also installs: zsh, Oh My Zsh, zsh-autosuggestions, zsh-syntax-highlighting.

### Omarchy desktop layer (automatic on Omarchy)

| Symlink | Target |
|---------|--------|
| `~/.config/hypr/bindings.lua` | `omarchy/config/hypr/bindings.lua` |
| `~/.config/hypr/monitors.lua` | `omarchy/config/hypr/monitors.lua` |
| `~/.config/hypr/hosts/<host>.lua` | `omarchy/config/hypr/hosts/<host>.lua` |
| `~/.config/nvim/lua/config/{options,keymaps}.lua` | `omarchy/config/nvim/lua/config/` |

After linking, the Hyprland config is reloaded and validated with `hyprctl configerrors`.

#### The rule: overlay, never override

Omarchy keeps improving its defaults on every `omarchy update`. Any file we copy
into this repo is frozen at the moment we copied it, so a tracked file stops
receiving those improvements and spreads the stale version to every other
machine. So the layer only ever touches Omarchy's **designated extension
points** — files Omarchy expects you to own, loaded *after* its defaults.

`~/.config/hypr/hyprland.lua` documents the pattern in Omarchy's own words:

> Put your personal overrides in these files. They're loaded after Omarchy's
> defaults so package updates can improve the defaults without rewriting your
> `~/.config/hypr` files.

The extension points worth knowing, and what each is for:

| Extension point | Use it for | Survives updates |
|-----------------|------------|------------------|
| `hypr/{bindings,input,looknfeel,monitors,autostart}.lua` | Hyprland overrides; real defaults stay in `/usr/share/omarchy/default/hypr/` | yes — loaded after defaults |
| `~/.config/nvim/lua/config/{options,keymaps,autocmds}.lua` | LazyVim settings and keymaps | yes — loaded on top of LazyVim |
| `~/.config/nvim/lua/plugins/*.lua` | Extra or overridden plugin specs | yes — merged by lazy.nvim |
| `omarchy plugin clone <id>` | Customizing a built-in bar widget | yes — clone is yours |
| `~/.config/omarchy/hooks/<type>.d/` | Scripts on system events | yes — additive directory |
| `~/.config/omarchy/extensions/omarchy-menu.jsonc` | Extending the menu; reuse an id to override a row | yes — merged |
| `~/.config/omarchy/themes/<name>/` | Overlaying a stock theme's colors | yes — overlay |
| `~/.config/omarchy/shell.json` | Bar layout, idle timings | **no — full override, no deep-merge** |

#### What is deliberately not tracked

Only files carrying real local content belong in the repo. As of now that is one
Hyprland binding, the monitor layout, and the Neovim overlay. These are left to
Omarchy because they are byte-for-byte equivalent to its shipped defaults:

| File | Why not |
|------|---------|
| `alacritty/alacritty.toml` | Functionally identical to Omarchy's default |
| `tmux/tmux.conf` | Identical, and the local copy is *behind* — missing `bind ?` and the `-N` descriptions that power `omarchy menu tmux keybindings` |
| `omarchy/shell.json` | Identical, and it is a full override with no deep-merge, so tracking it would freeze the bar against future defaults |
| `hypr/autostart.lua` | No statements, only Omarchy's comments |
| `hypr/{hyprland,input,looknfeel}.lua` | Unmodified Omarchy defaults |

Add any of these once it genuinely diverges — not before. `dfcheck` reports
what is currently linked.

#### Three shared configs are suppressed on Omarchy

Omarchy ships its own version of each, and layering the cross-platform one on top breaks it:

| Config | What goes wrong | What happens instead |
|--------|-----------------|----------------------|
| `~/.bashrc` | Replacing it drops `OMARCHY_PATH`, every Omarchy alias/function/completion, and PATH setup | `shell/bashrc` detects Omarchy, sources its bootstrap and rc first, then layers the shared exports/aliases/functions on top |
| `~/.config/nvim/init.vim` | Omarchy ships LazyVim as `init.lua`; Neovim aborts with `E5422: Conflicting configs` when both exist | Skipped. The layer overlays LazyVim's own `lua/config/` files instead, leaving `lua/plugins/` untouched |
| `~/.tmux.conf` | tmux loads it *and* `~/.config/tmux/tmux.conf`, XDG last — so Omarchy silently wins every conflict (prefix included) and you get a half-applied hybrid | Skipped. Omarchy's config is left unmanaged so updates keep improving it |

On Omarchy the prompt is left to Omarchy (it re-themes on `omarchy theme set`); `__setprompt` still runs everywhere else.

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
| `dotfiles-check` | `dfcheck` | Verify every managed config is still a symlink into this repo |
| `dotfiles-clean-backups` | `dfclean` | Remove all timestamped `.bak.*` backup files |

### `dfu` — update dotfiles

```bash
dfu              # uses saved profile from ~/.dotfiles_profile
dfu workstation  # override profile for this run
```

`dfu` will **abort** if there are uncommitted local changes, showing a `git status` so you can review and commit first.

### `install.sh` flags

```bash
./install.sh [server|workstation] [--skip-git] [--skip-omarchy] [--help]
```

| Flag | Description |
|------|-------------|
| `server` / `workstation` | Profile to install (default: `server`) |
| `--skip-git` | Skip the interactive git user name/email prompt |
| `--skip-omarchy` | Do not apply the Omarchy desktop layer even if Omarchy is detected |
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
│   └── tmux.conf               # Omarchy keybinding scheme, ported for non-Omarchy
├── git/
│   └── gitconfig               # Shared git config (colors, aliases — no user block)
├── bin/
│   ├── k8s-delete-stuck-namespaces  # Fix terminating K8s namespaces
│   ├── mergepdf                     # Merge PDFs via ghostscript
│   └── convertdocx2pdf             # Batch DOCX to PDF via pandoc
├── omarchy/                    # Omarchy only — auto-detected, mirrors ~/.config
│   └── config/
│       ├── hypr/               # bindings, monitors + hosts/<host>.lua
│       └── nvim/lua/config/    # LazyVim overlay (options, keymaps)
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
| Omarchy monitors | `omarchy/config/hypr/hosts/<hostname>.lua` (tracked) |

```bash
# Example ~/.local_profile
export PATH="$HOME/go/bin:$PATH"
alias k='kubectl'
```

Both `bashrc` and `zshrc` source this file automatically. Use it for anything machine-bound — a 1Password `SSH_AUTH_SOCK`, a local PATH entry, a host-specific alias.

Monitor layout is the one desktop setting that genuinely differs per machine, so it gets a tracked file rather than an ignored one. `hypr/monitors.lua` reads `/etc/hostname` and dispatches to `~/.config/hypr/hosts/<hostname>.lua`, which `install.sh` symlinks from the repo. Add one file per machine; a host with no file falls back to Hyprland autodetect and prints a warning at install time.

## Git user config

`install.sh` prompts for your name and email at install time and writes `~/.config/git/config` (the XDG path, which is where Omarchy already puts it). `setup.ps1` still writes `~/.gitconfig` on Windows.

The generated file:

1. Opens with a marked `[include]` block pulling in the shared `git/gitconfig` (aliases, colors, defaults)
2. Keeps your `[user]` block, and anything else already in the file, *below* it

**Order matters.** Git applies config in file order, so the include has to come first — otherwise the shared repo config would override this machine's own settings. With it at the top, `git/gitconfig` provides defaults and every local setting wins over them. That is what keeps a machine-local `init.defaultBranch = master` from being silently replaced by the repo's `main`.

Anything already in the file is preserved, including a `[commit] gpgsign` block and a 1Password `op-ssh-sign` program path. The marked block is rewritten on every run, so re-running is idempotent rather than stacking a new include each time. A leftover `~/.gitconfig` is backed up and removed, since it would take precedence over the XDG file.

On re-run, current values are shown as defaults — press Enter to keep them. When updating via `dfu`, the git prompt is skipped automatically (`--skip-git`).

## Backups

Before overwriting any existing config file, a timestamped backup is created:

```
~/.bashrc.bak.20250327143012
```

At the end of install you are offered the option to delete them. At any time, run `dfclean` (Linux) or `dfclean` (Windows PowerShell) to clean up all backup files.

## Commands reference

### Dotfiles management (both platforms)

| Command | Alias | Description |
|---------|-------|-------------|
| `dotfiles-update [profile]` | `dfu` | Pull + re-run install (skips git prompt) |
| `dotfiles-reload` | `dfr` | Reload shell config in the current session |
| `dotfiles-check` | `dfcheck` | Verify managed configs are still linked |
| `dotfiles-clean-backups` | `dfclean` | Remove all `.bak.*` backup files |

### Docker (both platforms)

| Command | Description |
|---------|-------------|
| `dc` | `docker compose` |
| `dcu` | `docker compose up -d` |
| `dcd` | `docker compose down` |
| `dcl` | `docker compose logs -f` |
| `dcdu` | down + up |
| `dps` | `docker ps` |
| `run-ollama` / `Run-Ollama` | Start Ollama container (creates on first run) |
| `ollama <args>` | Run ollama CLI via Docker |
| `run-it-tools` / `Run-ItTools` | Start IT-Tools at `http://localhost:8080` |

### Navigation (both platforms)

| Command | Description |
|---------|-------------|
| `..` | `cd ..` |
| `...` | `cd ../..` |
| `....` | `cd ../../..` |
| `up <n>` | Go up `n` directories (Linux/macOS) |
| `ll` | Long listing with hidden files |
| `la` | Long listing, all files |

### Linux-only aliases

| Alias | Command |
|-------|---------|
| `lx` / `lk` / `lt` / `lr` | Various sorted `ls` views |
| `rmd` | `rm -rf` |
| `h <term>` | `history \| grep <term>` |
| `p <term>` | `ps aux \| grep <term>` |
| `f <term>` | `find . \| grep <term>` |
| `mx` | `chmod a+x` |
| `sha1` | `openssl sha1` |
| `extract <file>` | Extract any archive format |
| `mkdirg <dir>` | `mkdir -p` + `cd` |
| `cpg` / `mvg` | Copy/move and `cd` to destination |
| `encodeb64 <str>` | Base64 encode (copies to clipboard if available) |
| `whatsmyip` | Show internal and external IP |
| `rename-all-sequentially <prefix> <ext>` | Bulk-rename files in current dir |

### Windows PowerShell functions

| Function | Alias | Description |
|----------|-------|-------------|
| `Update-Dotfiles [profile]` | `dfu` | Pull + re-run setup (skips git prompt) |
| `Invoke-ProfileReload` | `dfr` | `. $PROFILE` |
| `Invoke-DotfilesCleanBackups` | `dfclean` | Remove `.bak.*` backup files |
| `Run-Ollama` | — | Start Ollama container |
| `Run-ItTools` | — | Start IT-Tools container |
| `vi` | — | Alias for `vim` |

## Tmux

Keybindings follow **Omarchy's scheme**, so muscle memory carries between the
Omarchy desktops and every server and Ubuntu box. Omarchy machines keep their
own `~/.config/tmux/tmux.conf` — that file is Omarchy's to maintain, and
`omarchy update` keeps improving it. `tmux/tmux.conf` in this repo is the port
of that scheme for everywhere else.

- **Prefix**: `Ctrl-Space` (with `Ctrl-b` kept as a secondary prefix)
- **Panes**: `Alt-Enter` split vertical, `Alt-Shift-Enter` split horizontal, `Alt-Escape` kill — all without the prefix
- **Pane focus / resize**: `Ctrl-Alt-<arrow>` / `Ctrl-Alt-Shift-<arrow>` — note Omarchy reuses the vim letters: `prefix h` splits vertically and `prefix k` **kills the window**
- **Windows**: `Alt-1`…`Alt-9` jump, `Alt-Left`/`Alt-Right` cycle, `Alt-Shift-Left/Right` move
- **Sessions**: `Alt-Up`/`Alt-Down` switch; prefix `C`/`K`/`R` create, kill, rename
- **Copy mode**: vi keys, `v` select, `y` copy
- **Help**: prefix `?` — the Omarchy popup on a desktop, `list-keys -N` elsewhere
- **Reload**: prefix `q`
- **Mouse**: enabled

### Clipboard

Copy uses **OSC 52**, not `xclip`/`pbcopy`/`wl-copy`. tmux emits an escape
sequence that the *terminal* turns into a clipboard write, which means:

- **Nothing to install on a server.** No X11, no Wayland, no clipboard binary.
- **It works over SSH**, which `xclip` never did — yanking in a remote tmux lands in your local clipboard.
- The requirement moves to the **local terminal**, which must allow OSC 52 writes.

| Terminal | Status |
|----------|--------|
| Alacritty | Needs `[terminal] osc52 = "CopyPaste"` — Omarchy sets this; add it on a non-Omarchy install |
| Ghostty | Works by default (`clipboard-write = allow`) |
| Kitty | Works by default |
| foot | Works by default |
| VTE-based (GNOME Terminal, Tilix) | Needs VTE >= 0.72 |
| PuTTY | No OSC 52 support — use its own selection copy |

`set -as terminal-features ",*:clipboard"` is what forces tmux to emit the
sequence even when the terminfo entry lacks the `Ms` capability, which is the
usual reason OSC 52 silently does nothing.

**Pasting** needs no setup: OSC 52 *reads* are blocked by most terminals for
good reason, so paste with the terminal's own shortcut (`Ctrl+Shift+V` or
`Shift+Insert`) and bracketed paste handles the rest.

### Two more adaptations for non-Omarchy machines:

- **Clipboard is OSC 52** (`set-clipboard on`), not `xclip`/`pbcopy`. It works on Wayland, X11 and macOS — and unlike xclip it works straight out of an SSH session, which is the case that actually matters on a server.
- **Settings are version-gated.** `extended-keys`, `allow-passthrough` and `extended-keys-format` need tmux 3.2/3.3/3.4 respectively and are applied only where they exist, so an older tmux does not error at startup.

**Requires tmux >= 3.1** for the `-N` binding descriptions, which drive both the
help popup and the `list-keys -N` fallback. `install.sh` checks the version and
skips linking the config on anything older rather than leaving you with 40
broken bindings.

To re-sync after an Omarchy update changes the upstream bindings, diff against
`/usr/share/omarchy/config/tmux/tmux.conf`.

## Vim features

**Leader is `Space`** (local leader `\\`) on both sides — LazyVim's default on the
Omarchy desktops, and set explicitly in `vim/vimrc` for plain vim elsewhere, so
leader-based muscle memory carries across machines. In `vimrc` it is set before
`plug#begin`, since plugins resolve `<leader>` when their mappings are defined.
The trade-off is the usual one: `Space` no longer moves the cursor right in
normal mode.


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
