-- Tab title: show the running program with an icon, but leave OSC-set titles
-- (Claude Code, remote shells over ssh) exactly as the program set them.
local wezterm = require("wezterm")

local M = {}

-- icon per process basename — tweak to taste
local icons = {
    nvim = wezterm.nerdfonts.custom_vim,
    vim = wezterm.nerdfonts.custom_vim,
    git = wezterm.nerdfonts.dev_git,
    node = wezterm.nerdfonts.dev_nodejs_small,
    python = wezterm.nerdfonts.dev_python,
    cargo = wezterm.nerdfonts.dev_rust,
    docker = wezterm.nerdfonts.dev_docker,
    ssh = wezterm.nerdfonts.fa_server,
}

local function basename(s)
    return (s or ""):gsub(".*[/\\]", ""):gsub("%.exe$", "")
end

wezterm.on("format-tab-title", function(tab)
    local pane = tab.active_pane
    local proc = basename(pane.foreground_process_name)
    local title = pane.title or ""
    local icon = icons[proc] or wezterm.nerdfonts.cod_terminal
    -- 1-based tab number so it matches the jump shortcut.
    local num = tab.tab_index + 1

    -- A program set a custom OSC title (Claude Code, or a remote shell over
    -- ssh) iff the title isn't just echoing the process name. Show it verbatim
    -- but keep the icon + number prefix.
    if title ~= "" and title ~= proc then
        return " " .. icon .. " " .. num .. ": " .. title .. " "
    end

    return " " .. icon .. " " .. num .. ": " .. (proc ~= "" and proc or "shell") .. " "
end)

function M.apply_to_config(config)
    -- Force a periodic repaint so the process name stays current.
    config.status_update_interval = 1000
end

return M
