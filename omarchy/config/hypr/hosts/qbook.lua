-- qbook — 15.4" built-in panel

-- 1x scaling: the built-in eDP-1 panel is 1920x1080 on a ~15.4" screen (~143 DPI),
-- so "auto" picking 2x wasted half the usable desktop area (960x540 logical).
local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })
