-- Pull in the wezterm API
local wezterm = require "wezterm"
local mux = wezterm.mux
-- This will hold the configuration.
local config = wezterm.config_builder()

-- Set the color scheme depending on the system setting
local function get_appearance()
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end
  return "Dark"
end

local function scheme_for_appearance(appearance)
  if appearance:find "Dark" then
    return "Humanoid dark (base16)"
  else
    return "Horizon Light (base16)"
  end
end

config.color_scheme = scheme_for_appearance(get_appearance())

-- Remove all padding
config.window_padding = { left = 10, right = 10, top = 10, bottom = 10 }

-- URLs in Markdown files are not handled properly by default
-- Source: https://github.com/wez/wezterm/issues/3803#issuecomment-1608954312
config.hyperlink_rules = {
  -- Matches: a URL in parens: (URL)
  {
    regex = "\\((\\w+://\\S+)\\)",
    format = "$1",
    highlight = 1,
  },
  -- Matches: a URL in brackets: [URL]
  {
    regex = "\\[(\\w+://\\S+)\\]",
    format = "$1",
    highlight = 1,
  },
  -- Matches: a URL in curly braces: {URL}
  {
    regex = "\\{(\\w+://\\S+)\\}",
    format = "$1",
    highlight = 1,
  },
  -- Matches: a URL in angle brackets: <URL>
  {
    regex = "<(\\w+://\\S+)>",
    format = "$1",
    highlight = 1,
  },
  -- Then handle URLs not wrapped in brackets
  {
    -- Before
    --regex = '\\b\\w+://\\S+[)/a-zA-Z0-9-]+',
    --format = '$0',
    -- After
    regex = "[^(]\\b(\\w+://\\S+[)/a-zA-Z0-9-]+)",
    format = "$1",
    highlight = 1,
  },
  -- implicit mailto link
  {
    regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b",
    format = "mailto:$0",
  },
}

wezterm.on("gui-startup", function()
  local tab, pane, window = mux.spawn_window{}
  window:gui_window():maximize()
end)

local is_linux = function()
  return wezterm.target_triple:find "linux" ~= nil
end

local is_darwin = function()
  return wezterm.target_triple:find "darwin" ~= nil
end

local terminal_key_mod = "CTRL"
if is_darwin() then
  terminal_key_mod = "CMD"
end

config.keys = {
  -- {
  --   key = "F",
  --   mods = terminal_key_mod,
  --   action = wezterm.action.ToggleFullScreen,
  -- },
  {
    key = "f",
    mods = terminal_key_mod,
    action = wezterm.action.Search("CurrentSelectionOrEmptyString"),
  },
  {
    key = "w",
    mods = terminal_key_mod,
    action = wezterm.action.CloseCurrentTab { confirm = false },
  },
  {
    key = "DownArrow",
    mods = terminal_key_mod,
    action = wezterm.action_callback(function(window, pane)
      local tab = window:mux_window():active_tab()
      if tab:get_pane_direction "Left" ~= nil then
        window:perform_action(wezterm.action.ActivatePaneDirection "Left", pane)
      else
        window:perform_action(wezterm.action.ActivateTabRelative(-1), pane)
      end
    end),
  },
  {
    key = "UpArrow",
    mods = terminal_key_mod,
    action = wezterm.action_callback(function(window, pane)
      local tab = window:mux_window():active_tab()
      if tab:get_pane_direction "Right" ~= nil then
        window:perform_action(wezterm.action.ActivatePaneDirection "Right", pane)
      else
        window:perform_action(wezterm.action.ActivateTabRelative(1), pane)
      end
    end),
  },
  {
    key = "1",
    mods = terminal_key_mod,
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(wezterm.action.ActivateTab(0), pane)
    end),
  },
  {
    key = "2",
    mods = terminal_key_mod,
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(wezterm.action.ActivateTab(1), pane)
    end),
  },
  {
    key = "3",
    mods = terminal_key_mod,
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(wezterm.action.ActivateTab(2), pane)
    end),
  },
  {
    key = "4",
    mods = terminal_key_mod,
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(wezterm.action.ActivateTab(3), pane)
    end),
  },
  {
    key = "5",
    mods = terminal_key_mod,
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(wezterm.action.ActivateTab(4), pane)
    end),
  },
  {
    key = "6",
    mods = terminal_key_mod,
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(wezterm.action.ActivateTab(5), pane)
    end),
  },
  {
    key = "7",
    mods = terminal_key_mod,
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(wezterm.action.ActivateTab(6), pane)
    end),
  },
  {
    key = "8",
    mods = terminal_key_mod,
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(wezterm.action.ActivateTab(7), pane)
    end),
  },
  {
    key = "9",
    mods = terminal_key_mod,
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(wezterm.action.ActivateTab(8), pane)
    end),
  },
  {
    key = "0",
    mods = terminal_key_mod,
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(wezterm.action.ActivateTab(9), pane)
    end),
  },
}

-- Font configuration
config.font = wezterm.font "0xProto Nerd Font Mono"
config.freetype_load_target = "Light"
config.freetype_render_target = "HorizontalLcd"

-- Remove the title bar from the window
config.window_decorations = "INTEGRATED_BUTTONS | RESIZE"

-- Don't hide cursor when typing
config.hide_mouse_cursor_when_typing = false

-- Return the configuration to wezterm
return config
