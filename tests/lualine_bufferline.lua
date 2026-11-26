-- Run with the full configuration:
-- nvim --headless -i NONE '+lua dofile("tests/lualine_bufferline.lua")' '+qa!'
local api = vim.api
local lualine = require "lualine"
local opts = require "lualine.utils.nvim_opts"
local original_set = opts.set
local refresh_config = vim.deepcopy(lualine.get_config().options.refresh)
local writes = {}
opts.set = function(name, ...)
  writes[#writes + 1] = name
  return original_set(name, ...)
end
local function assert_tabline_only()
  assert(#writes > 0, "Switch must refresh synchronously")
  for _, name in ipairs(writes) do
    assert(name == "tabline", "Immediate refresh must not touch " .. name)
  end
  writes = {}
end
local function create(name)
  local buf = api.nvim_create_buf(true, false)
  api.nvim_buf_set_name(buf, name)
  return buf
end
local first = create "lualine-bufferline-first"
local second = create "lualine-bufferline-second"
api.nvim_set_current_buf(first)
assert_tabline_only()
local before = vim.o.tabline
api.nvim_set_current_buf(second)
assert_tabline_only()
assert(
  vim.o.tabline ~= before,
  "Current-buffer highlight must update immediately"
)
local after = vim.o.tabline
lualine.refresh { place = { "tabline" }, force = true }
assert(vim.o.tabline == after, "Tabline must already match the current buffer")
assert_tabline_only()

-- Window and tab entry use the same immediate, tabline-only path.
for _, event in ipairs { "WinEnter", "TabEnter" } do
  api.nvim_exec_autocmds(event, { group = "LualineFiletypeRefresh" })
  assert_tabline_only()
end

-- Documentation/completion floats must not replace the active editor tab.
local float = api.nvim_open_win(api.nvim_create_buf(false, true), true, {
  relative = "editor",
  row = 1,
  col = 1,
  width = 20,
  height = 3,
  style = "minimal",
})
assert(#writes == 0, "Float entry must not force a tabline refresh")
assert(vim.o.tabline == after, "Float entry must retain the editor tabline")
api.nvim_win_close(float, true)
assert_tabline_only()
assert(
  vim.deep_equal(lualine.get_config().options.refresh, refresh_config),
  "Existing refresh timers must stay unchanged"
)

-- Lualine normally reduces terminals to their shell name. Show the actual
-- buffer name, which the terminal monitor updates with the current process.
local terminal = api.nvim_create_buf(true, false)
vim.api.nvim_open_term(terminal, {})
local terminal_name = "Run pytest  󰄛"
api.nvim_buf_set_name(terminal, terminal_name)
api.nvim_set_current_buf(terminal)
assert_tabline_only()
assert(
  vim.o.tabline:find(terminal_name, 1, true),
  "Terminal tab must show its buffer name"
)
assert(
  not vim.o.tabline:find(vim.fn.getcwd() .. "/", 1, true),
  "Terminal tab must not show the CWD prefix"
)
local updated_name = "Run cargo  󰄛"
api.nvim_buf_set_name(terminal, updated_name)
lualine.refresh { place = { "tabline" }, force = true }
assert(
  vim.o.tabline:find(updated_name, 1, true),
  "Terminal tab must follow buffer renames"
)

opts.set = original_set
print "Immediate bufferline refresh checks passed"
