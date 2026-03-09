local map = require "mappings.map"
local is_normal_buffer = require "utils.is_normal_buffer"
map("t", "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true })
map("t", "<A-a>", "<C-\\><C-n><C-w>h", { noremap = true, silent = true })
map("t", "<A-s>", "<C-\\><C-n><C-w>j", { noremap = true, silent = true })
map("t", "<A-w>", "<C-\\><C-n><C-w>k", { noremap = true, silent = true })
map("t", "<A-d>", "<C-\\><C-n><C-w>l", { noremap = true, silent = true })

local taken_names = {}

local function unique_name(base)
  if not taken_names[base] then
    taken_names[base] = true
    return base
  end
  local i = 1
  while true do
    local candidate = base .. " (" .. i .. ")"
    if not taken_names[candidate] then
      taken_names[candidate] = true
      return candidate
    end
    i = i + 1
  end
end

local function random_char()
  math.randomseed(os.time())

  local chars = {
    "",
    "",
    "",
    "󱜿",
    "󱦡",
    "󰟻",
    "󰨶",
    "󱗫",
    "󰉀",
    "󱠂",
    "󱩡",
    "󱀆",
    "󰏖",
    "󱗃",
    "󰢗",
    "󱒕",
    "",
    "󰚆",
    "󰭥",
    "",
    "󰊘",
    "",
    "",
    "󱁏",
    "",
    "",
    "",
    "󰀸",
  }
  return chars[math.random(#chars)]
end

map("n", "<Leader>tn", function()
  if is_normal_buffer() then
    vim.cmd.terminal()
    vim.cmd.BufferPin()
    local base = "  Terminal " .. random_char() .. " "
    local name = unique_name(base)
    vim.api.nvim_buf_set_name(0, name)
  else
    vim.notify("Cannot start terminal from non-normal buffer", vim.diagnostic.severity.WARN, { timeout = 3000 })
  end
end, { desc = "Terminal: new" })

map("n", "<Leader>tr", function()
  local old = vim.api.nvim_buf_get_name(0)
  taken_names[old] = nil
  local base = "  Terminal " .. vim.fn.input { prompt = "New buf name: " }
  local name = unique_name(base)
  vim.api.nvim_buf_set_name(0, name)
end, { desc = "Terminal: rename buffer" })
