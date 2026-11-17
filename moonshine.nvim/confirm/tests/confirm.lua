-- Run from the repository root:
-- nvim --clean --headless -l moonshine.nvim/confirm/tests/confirm.lua
vim.opt.runtimepath:append(vim.fn.getcwd() .. "/moonshine.nvim/confirm")
local plugin = require "moonshine.confirm"
local original = vim.fn.confirm
local list_uis, getcharstr = vim.api.nvim_list_uis, vim.fn.getcharstr
local windows, buffers = #vim.api.nvim_list_wins(), #vim.api.nvim_list_bufs()
local current = vim.api.nvim_get_current_win()
local fallback_calls = 0
local fallback_default
vim.fn.confirm = function(_, _, default)
  fallback_calls = fallback_calls + 1
  fallback_default = default
  return 42
end
plugin.setup()
local override = vim.fn.confirm
plugin.setup()
assert(vim.fn.confirm == override, "setup must be idempotent")
assert(vim.fn.confirm "Headless?" == 42)
vim.api.nvim_list_uis = function()
  return { {} }
end

local function check(keys, expected, message, choices, default)
  local index = 0
  vim.fn.getcharstr = function()
    index = index + 1
    assert(vim.api.nvim_get_current_win() == current, "float took focus")
    local floats = 0
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local config = vim.api.nvim_win_get_config(win)
      if config.relative ~= "" then
        floats = floats + 1
        assert(config.focusable == false)
        assert(config.border[1] ~= nil)
        if choices == nil then
          local lines = vim.api.nvim_buf_get_lines(
            vim.api.nvim_win_get_buf(win),
            0,
            -1,
            false
          )
          assert(table.concat(lines, "\n"):find("<CR>: Yes", 1, true))
        end
      end
    end
    assert(floats == 1, "confirmation float missing")
    assert(keys[index], "unexpected extra key read")
    return keys[index]
  end
  assert(
    vim.fn.confirm(message or "Continue?", choices or "&Yes\n&No", default)
      == expected
  )
  assert(#vim.api.nvim_list_wins() == windows, "window leak")
  assert(#vim.api.nvim_list_bufs() == buffers, "buffer leak")
end

check({ "\r" }, 1)
check({ "\r" }, 1, nil, nil, 2)
check({ "\r" }, 1, nil, nil, 0)
check({ "\r" }, 1, nil, nil, 99)
check({ "\r" }, 2, "Continue?", "&No\n&Yes", 1)
check({ "\r" }, 2, "Save?", "&Save\n&Cancel", 2)
check({ "\r" }, 0, "Save?", "&Save\n&Cancel", 0)
check({ "x", "Y" }, 1)
check({ "n" }, 2)
check({ "\027" }, 0)
check({ "\003" }, 0)
check({ "a" }, 2, "Save?", "&Save\nSave &All\n&Cancel", 3)
check({ "o" }, 1, "Okay?", "")
check({ "д" }, 1, "Выбрать?", "&Да\n&Нет", 2)
check({ "y" }, 1, "Multiline\n" .. string.rep("wrapped text ", 15))
assert(vim.fn.confirm(string.rep("too tall\n", 100), "&Yes\n&No", 2) == 42)
assert(fallback_default == 1)
local columns = vim.o.columns
vim.o.columns = 10
assert(vim.fn.confirm("Too narrow?", "&No\n&Yes", 0) == 42)
assert(fallback_default == 2)
vim.o.columns = columns
assert(fallback_calls == 3)

vim.fn.getcharstr = function()
  error "unexpected read failure"
end
assert(not pcall(vim.fn.confirm, "Failure?"))
assert(#vim.api.nvim_list_wins() == windows)
assert(#vim.api.nvim_list_bufs() == buffers)
check({ "y" }, 1) -- Failure must not leave the reentrancy guard active.
plugin.teardown()
assert(vim.fn.confirm ~= override)
vim.fn.confirm = original
vim.api.nvim_list_uis, vim.fn.getcharstr = list_uis, getcharstr
print "moonshine.confirm: passed"
