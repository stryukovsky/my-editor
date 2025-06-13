-- require "which-key"
function ContainsNonAscii(str)
  -- Check if the input is a string
  if type(str) ~= "string" then
    return false
  end

  -- Iterate through each character in the string
  for i = 1, #str do
    local byte = str:byte(i)
    -- ASCII characters are in range 0-127
    if byte > 127 then
      return true
    end
  end

  return false
end

return {
  ---@type false | "classic" | "modern" | "helix"
  preset = "modern",
  ---@param mapping wk.Mapping
  filter = function(mapping)
    -- example to exclude mappings without a description
    return mapping.desc and mapping.desc ~= "" and not ContainsNonAscii(mapping.lhs)
  end,
  keys = {
    scroll_down = "<Down>", -- binding to scroll down inside the popup
    scroll_up = "<Up>", -- binding to scroll up inside the popup
  },
  sort = { "alphanum", "group", "local", "order", "mod" },
  ---@type number|fun(node: wk.Node):boolean?
  expand = 10, -- expand groups when <= n mappings
}
