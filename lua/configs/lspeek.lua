local lspeek = require "lspeek"

lspeek.setup {
  window = {
    width = 90,
    height = 22,
    border = "rounded",
    win_opts = {
      signcolumn = "no",
      winbar = "",
      number = true,
    },
  },
  stack_limit = 5,
  -- One type is the common case; skip vim.ui.select and open the float.
  select_first = true,
  keymaps = {
    close = "q",
    split = "s",
    vsplit = "v",
    enter = "<CR>",
    tab = "t",
    prev = "[",
    next = "]",
  },
}

-- Peek opens asynchronously after the LSP response. Arm a short window so the
-- next editor-relative float can be tagged as a peek preview.
local expecting_peek = false

local function arm_peek()
  expecting_peek = true
  vim.defer_fn(function()
    expecting_peek = false
  end, 3000)
end

for _, name in ipairs { "peek_definition", "peek_type_definition" } do
  local orig = lspeek[name]
  lspeek[name] = function(...)
    arm_peek()
    return orig(...)
  end
end

local function mark_peek_win()
  if not expecting_peek then
    return
  end
  local win = vim.api.nvim_get_current_win()
  local cfg = vim.api.nvim_win_get_config(win)
  if cfg.relative ~= "" then
    vim.w[win].lspeek = true
  end
end

vim.api.nvim_create_autocmd({ "WinNew", "WinEnter" }, {
  callback = mark_peek_win,
})

-- Destroy the peek UI when the cursor leaves it. Staying on another stacked
-- peek does not count as leaving.
vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    if not vim.w.lspeek then
      return
    end
    vim.schedule(function()
      if vim.w.lspeek then
        return
      end
      lspeek.close_all()
    end)
  end,
})
