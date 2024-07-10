local wezterm = require("wezterm")
local config = {}
config.font = wezterm.font("JetBrains Mono")
config.harfbuzz_features = {"calt=0", "clig=0", "liga=0"}
config.font_size = 16.0
config.enable_csi_u_key_encoding = true
config.color_scheme_dirs = {"~/.config/wezterm/colors/"}
config.color_scheme = "kanagawabones"
config.window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
}
config.keys = {
    {key = "LeftArrow", mods = "OPT", action = wezterm.action({SendString = "\x1bb"})},
    {key = "RightArrow", mods = "OPT", action = wezterm.action({SendString = "\x1bf"})},
    {key = "LeftArrow", mods = "SHIFT|OPT", action = wezterm.action.MoveTabRelative(-1)},
    {key = "RightArrow", mods = "SHIFT|OPT", action = wezterm.action.MoveTabRelative(1)},
}
config.audible_bell = "Disabled"

return config
