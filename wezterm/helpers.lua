local wezterm = require("wezterm")

local module = {}

local function private_helper()
  wezterm.log_error("Hello")
end

function module.apply_to_config(config)
  config.font_size = 15
  config.hide_tab_bar_if_only_one_tab = true
  config.window_decorations = "RESIZE"
  -- config.color_scheme = "Abernathy"
  -- config.color_scheme = "Adventure"
  config.color_scheme = "Apple System Colors"

  config.window_background_opacity = 0.95
  config.macos_window_background_blur = 30
  config.font = wezterm.font("FiraCode Nerd Font")
end

return module
