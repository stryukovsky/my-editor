-- require "which-key"

return {
  ---@type false | "classic" | "modern" | "helix"
  preset = "modern",
  ---@param mapping wk.Mapping
  filter = function(mapping)
    -- example to exclude mappings without a description
    return mapping.desc and mapping.desc ~= ""
  end,
  keys = {
    scroll_down = "<Down>", -- binding to scroll down inside the popup
    scroll_up = "<Up>", -- binding to scroll up inside the popup
  },
  sort = { "alphanum", "group", "local", "order", "mod" },
  ---@type number|fun(node: wk.Node):boolean?
  expand = 10, -- expand groups when <= n mappings
}
