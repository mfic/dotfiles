-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all
--
-- Monitor layout is the one desktop setting that is genuinely per-machine, so
-- this file only dispatches. Put the real config in a host file:
--
--   dotfiles/omarchy/config/hypr/hosts/<hostname>.lua
--
-- It is symlinked to ~/.config/hypr/hosts/<hostname>.lua by install.sh, the
-- same way ~/.local_profile carries per-machine shell settings.

local host = "unknown"
local f = io.open("/etc/hostname")
if f then
    host = (f:read("l") or "unknown"):gsub("%s+", "")
    f:close()
end

local host_config = os.getenv("HOME") .. "/.config/hypr/hosts/" .. host .. ".lua"
local h = io.open(host_config)
if h then
    h:close()
    dofile(host_config)
else
    -- No host file yet: let Hyprland autodetect. Copy an existing host file to
    -- hosts/<hostname>.lua and adjust once you know what the panel needs.
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
end
