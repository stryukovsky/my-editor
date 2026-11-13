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

local config = {
  ---@type false | "classic" | "modern" | "helix"
  preset = "modern",
  icons = {
    mappings = false,
  },
  ---@param mapping wk.Mapping
  filter = function(mapping)
    -- example to exclude mappings without a description
    return mapping.desc and mapping.desc ~= "" and not ContainsNonAscii(mapping.lhs)
  end,
  delay = 0,
  keys = {
    scroll_down = "<Down>", -- binding to scroll down inside the popup
    scroll_up = "<Up>", -- binding to scroll up inside the popup
  },
  triggers = {
    { "<leader>", mode = { "n", "v" } },
    { "<auto>", mode = "nixsotc" },
  },
  sort = {
    function(item)
      return item.group and 0 or 1
    end,
    "alphanum", "local", "order", "mod",
  },
  ---@type number|fun(node: wk.Node):boolean?
  expand = 0, -- keep groups collapsed until their prefix is pressed
}

local wk = require "which-key"
wk.setup(config)

wk.add({
  {
    mode = { "n", "v" },
    { "<leader>b", group = "Bigfiles" },
    { "<leader>g", group = "Git" },
    { "<leader>t", group = "Tasks, tests & terminals" },
    { "<leader>c", group = "Code & conflicts" },
    { "<leader>d", group = "Debug" },
    { "<leader>f", group = "Find & format" },
    { "<leader>l", group = "LSP and logs" },
    { "<leader>p", group = "Yanky, Python, PDF & projects" },
    { "<leader>s", group = "Scenarios, swaps & spell actions" },
    { "<leader>y", group = "yank problems, paths, or TODOs" },
    { "<leader>e", group = "Exec script right now!" },
    { "<leader>v", group = "Visualize" },
    { "<leader>r", group = "Rename, Refresh and cuRl" },
    { "<leader>m", group = "Markdown & Marks" },
    { "<leader>j", group = "Jobs (todo file)" },
    { "<leader>R", group = "Refactor" },
  },
})
