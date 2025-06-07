require("auto-save").setup {
  trigger_events = { "InsertLeave", --[[ "TextChanged" ]] }, -- vim events that trigger auto-save. See :h events
  enabled = true, -- start auto-save when the plugin is loaded (i.e. when your package manager loads it)
}
