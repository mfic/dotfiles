-- WezTerm config — one file for Windows and Linux, branching on target_triple.
-- Windows: linked to ~/.wezterm.lua by windows/setup.ps1
-- Linux:   linked to ~/.config/wezterm/wezterm.lua by install.sh (only if wezterm is installed)
-- Reference: https://wezterm.org/config/lua/config/index.html
--
-- Key scheme mirrors tmux/tmux.conf (the Omarchy tmux bindings) so muscle memory
-- carries over. Every tmux key is "smart": in a local shell it performs the WezTerm
-- equivalent; when the pane is running ssh/wsl/mosh or lives in a non-local domain it
-- is passed through untouched so a *remote* tmux receives it instead.

local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux
local config = wezterm.config_builder()
local is_windows = wezterm.target_triple:find('windows') ~= nil

-- Font: what setup.ps1 installs via oh-my-posh. WezTerm appends its bundled
-- JetBrains Mono, Nerd Font Symbols and Noto Color Emoji as fallback automatically.
config.font = wezterm.font('FiraCode Nerd Font')
config.font_size = 11.0
config.scrollback_lines = 50000          -- match tmux history-limit
config.audible_bell = 'Disabled'         -- matches the dotfiles' bell-style none
config.window_close_confirmation = 'NeverPrompt'
-- OSC 52 clipboard writes are honoured by default; nothing to enable.

if is_windows then
  local pwsh = 'C:/Program Files/PowerShell/7/pwsh.exe'
  config.default_prog = { pwsh, '-NoLogo' }
  config.launch_menu = {
    { label = 'PowerShell 7',           args = { pwsh, '-NoLogo' } },
    { label = 'Windows PowerShell 5.1', args = { 'powershell.exe', '-NoLogo' } },
    { label = 'Git Bash',               args = { 'C:/Program Files/Git/bin/bash.exe', '--login', '-i' } },
  }
  -- WSL distros (Ubuntu, archlinux, ...) appear automatically as WSL:<name> domains.
  -- WezTerm otherwise points SSH_AUTH_SOCK at its own agent proxy, which Windows
  -- OpenSSH cannot use; unset, ssh falls back to the 1Password openssh-ssh-agent pipe.
  config.mux_enable_ssh_agent = false
end

-- SSH: keep the SSH:/SSHMUX: domains auto-generated from ~/.ssh/config.
-- WezTerm's built-in ssh client has no ProxyJump — use plain `ssh` for those hosts.
config.ssh_domains = wezterm.default_ssh_domains()

-- Kubernetes pod names for QuickSelect (in addition to the built-in patterns)
config.quick_select_patterns = { '[a-z0-9-]+-[a-z0-9]{8,10}-[a-z0-9]{5}' }

---------------------------------------------------------------------------
-- Remote detection: is this pane (probably) hosting a remote tmux?
-- https://wezterm.org/config/lua/pane/get_foreground_process_name.html
--   Windows: walks the pty's process tree, returns the newest descendant
--   (pwsh -> ssh.exe reports ssh.exe). Mux/SSH-domain panes return nil.
---------------------------------------------------------------------------
local REMOTE_PROCS = {
  ['ssh'] = true, ['ssh.exe'] = true,
  ['wsl'] = true, ['wsl.exe'] = true, ['wslhost.exe'] = true,
  ['mosh'] = true, ['mosh-client'] = true,
  ['et'] = true, -- eternal terminal
}

local function is_remote(pane)
  local ok, domain = pcall(function() return pane:get_domain_name() end)
  if ok and domain and domain ~= 'local' then
    return true
  end
  local proc = pane:get_foreground_process_name()
  if not proc then
    return false
  end
  local base = proc:match('([^/\\]+)$') or proc
  return REMOTE_PROCS[base:lower()] == true
end

-- Same key as tmux: local action when local, raw key when remote.
local function tmux_key(key, mods, action)
  return {
    key = key,
    mods = mods,
    action = wezterm.action_callback(function(win, pane)
      if is_remote(pane) then
        win:perform_action(act.SendKey { key = key, mods = mods }, pane)
      else
        win:perform_action(action, pane)
      end
    end),
  }
end

local function rename_tab()
  return act.PromptInputLine {
    description = 'Rename window',
    action = wezterm.action_callback(function(win, pane, line)
      if line then win:active_tab():set_title(line) end
    end),
  }
end

local function rename_workspace()
  return act.PromptInputLine {
    description = 'Rename session',
    action = wezterm.action_callback(function(win, pane, line)
      if line and #line > 0 then
        mux.rename_workspace(mux.get_active_workspace(), line)
      end
    end),
  }
end

local function new_workspace()
  return act.PromptInputLine {
    description = 'New session name',
    action = wezterm.action_callback(function(win, pane, line)
      if line and #line > 0 then
        win:perform_action(act.SwitchToWorkspace { name = line }, pane)
      end
    end),
  }
end

-- "Kill session": close every tab in every window of the current workspace.
local function kill_workspace()
  return wezterm.action_callback(function(win, pane)
    local ws = mux.get_active_workspace()
    for _, w in ipairs(mux.all_windows()) do
      if w:get_workspace() == ws then
        local gui = w:gui_window()
        for _, t in ipairs(w:tabs()) do
          t:activate()
          gui:perform_action(act.CloseCurrentTab { confirm = false }, t:active_pane())
        end
      end
    end
  end)
end

---------------------------------------------------------------------------
-- Prefix-less keys (tmux `bind -n`), same chords as tmux.conf
---------------------------------------------------------------------------
config.keys = {
  -- Hand this to 1Password Quick Access instead of WezTerm's default
  { key = 'Space', mods = 'CTRL|SHIFT', action = act.DisableDefaultAssignment },

  -- Prefix: Ctrl+Space, like tmux. Passed through when remote; one-shot key table when local.
  {
    key = 'Space', mods = 'CTRL',
    action = wezterm.action_callback(function(win, pane)
      if is_remote(pane) then
        win:perform_action(act.SendKey { key = 'Space', mods = 'CTRL' }, pane)
      else
        win:perform_action(
          act.ActivateKeyTable { name = 'tmux_prefix', one_shot = true, timeout_milliseconds = 2000 },
          pane)
      end
    end),
  },

  -- Panes
  tmux_key('Enter',  'ALT',       act.SplitVertical   { domain = 'CurrentPaneDomain' }), -- tmux -v: stacked
  tmux_key('Enter',  'SHIFT|ALT', act.SplitHorizontal { domain = 'CurrentPaneDomain' }), -- tmux -h: side by side
  tmux_key('Escape', 'ALT',       act.CloseCurrentPane { confirm = false }),
  tmux_key('LeftArrow',  'CTRL|ALT', act.ActivatePaneDirection 'Left'),
  tmux_key('RightArrow', 'CTRL|ALT', act.ActivatePaneDirection 'Right'),
  tmux_key('UpArrow',    'CTRL|ALT', act.ActivatePaneDirection 'Up'),
  tmux_key('DownArrow',  'CTRL|ALT', act.ActivatePaneDirection 'Down'),
  tmux_key('LeftArrow',  'CTRL|SHIFT|ALT', act.AdjustPaneSize { 'Left', 5 }),
  tmux_key('RightArrow', 'CTRL|SHIFT|ALT', act.AdjustPaneSize { 'Right', 5 }),
  tmux_key('UpArrow',    'CTRL|SHIFT|ALT', act.AdjustPaneSize { 'Up', 5 }),
  tmux_key('DownArrow',  'CTRL|SHIFT|ALT', act.AdjustPaneSize { 'Down', 5 }),

  -- Windows (tmux) = tabs (WezTerm)
  tmux_key('LeftArrow',  'ALT',       act.ActivateTabRelative(-1)),
  tmux_key('RightArrow', 'ALT',       act.ActivateTabRelative(1)),
  tmux_key('LeftArrow',  'SHIFT|ALT', act.MoveTabRelative(-1)),
  tmux_key('RightArrow', 'SHIFT|ALT', act.MoveTabRelative(1)),

  -- Sessions (tmux) = workspaces (WezTerm)
  tmux_key('UpArrow',   'ALT', act.SwitchWorkspaceRelative(-1)),
  tmux_key('DownArrow', 'ALT', act.SwitchWorkspaceRelative(1)),

  -- Extras that do not exist in tmux.conf (Ctrl+Shift is free of the tmux scheme)
  { key = 'h', mods = 'CTRL|SHIFT', action = act.QuickSelect },
  { key = 'l', mods = 'CTRL|SHIFT|ALT',
    action = act.ShowLauncherArgs { flags = 'FUZZY|LAUNCH_MENU_ITEMS|DOMAINS|WORKSPACES' } },
  -- Defaults kept: Ctrl+Shift+T tab, Ctrl+Shift+Z zoom, Ctrl+Shift+F search,
  -- Ctrl+Shift+X copy mode (v = select, y = yank, as in tmux copy-mode-vi), Ctrl+Shift+P palette.
}

-- Alt+1..9: window N (tab N)
for i = 1, 9 do
  table.insert(config.keys, tmux_key(tostring(i), 'ALT', act.ActivateTab(i - 1)))
end

---------------------------------------------------------------------------
-- Prefixed keys (tmux `bind <key>`), after Ctrl+Space
---------------------------------------------------------------------------
config.key_tables = {
  tmux_prefix = {
    { key = 'Space', mods = 'CTRL', action = act.SendKey { key = 'Space', mods = 'CTRL' } }, -- send-prefix
    { key = 'q', action = act.ReloadConfiguration },
    -- panes
    { key = 'h', action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },
    { key = 'v', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'x', action = act.CloseCurrentPane { confirm = false } },
    -- windows
    { key = 'r', action = rename_tab() },
    { key = 'c', action = act.SpawnTab 'CurrentPaneDomain' },
    { key = 'k', action = act.CloseCurrentTab { confirm = false } },
    -- sessions
    { key = 'R', mods = 'SHIFT', action = rename_workspace() },
    { key = 'C', mods = 'SHIFT', action = new_workspace() },
    { key = 'K', mods = 'SHIFT', action = kill_workspace() },
    { key = 'P', mods = 'SHIFT', action = act.SwitchWorkspaceRelative(-1) },
    { key = 'N', mods = 'SHIFT', action = act.SwitchWorkspaceRelative(1) },
    { key = 'Escape', action = 'PopKeyTable' },
  },
}

---------------------------------------------------------------------------
-- Copy & paste: Windows Terminal muscle memory.
-- Defaults already give: mouse selection copies to clipboard, Ctrl+Shift+C/V,
-- Shift+Insert paste, Shift+drag to select inside tmux/k9s (bypasses mouse
-- reporting), OSC 52 from remote tmux/nvim. Missing vs Windows Terminal is
-- right click = copy selection if one exists, otherwise paste.
---------------------------------------------------------------------------
config.mouse_bindings = {
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = wezterm.action_callback(function(win, pane)
      local sel = win:get_selection_text_for_pane(pane)
      if sel and #sel > 0 then
        win:perform_action(act.CopyTo 'ClipboardAndPrimarySelection', pane)
        win:perform_action(act.ClearSelection, pane)
      else
        win:perform_action(act.PasteFrom 'Clipboard', pane)
      end
    end),
  },
}

-- Show the active workspace (tmux "session") and pending prefix in the status bar
wezterm.on('update-right-status', function(window, pane)
  local parts = { window:active_workspace() }
  if window:active_key_table() then
    table.insert(parts, 1, '[prefix]')
  end
  window:set_right_status(' ' .. table.concat(parts, ' │ ') .. ' ')
end)

return config
