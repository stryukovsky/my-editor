local yanky = require "yanky"
local mapping = require "yanky.telescope.mapping"
local utils = require "yanky.utils"

yanky.setup {
  ring = {
    history_length = 100,
    storage = "memory",
  },
  preserve_cursor_position = {
    enabled = true,
  },
  picker = {
    telescope = {
      mappings = {
        default = mapping.put "P",
        i = {
          ["<c-g>"] = mapping.put "p",
          ["<c-k>"] = mapping.put "P",
          ["<c-x>"] = mapping.delete(),
          ["<c-r>"] = mapping.set_register(utils.get_default_register()),
        },
        n = {
          p = mapping.put "P",
          d = mapping.delete(),
          r = mapping.set_register(utils.get_default_register()),
        },
      },
    },
  },
  highlight = {
    on_put = false,
    on_yank = false,
    timer = 100,
  },
}

local visual_flashes = {}

local function flash_visual_yank()
  -- Visual selection backgrounds take precedence over the yank extmark.
  local win = vim.api.nvim_get_current_win()
  local highlights = vim.opt_local.winhighlight:get()
  local previous = visual_flashes[win]
  local flash = { original = highlights.Visual }
  if previous and highlights.Visual == "VisualYankFlash" then
    flash.original = previous.original
  end
  visual_flashes[win] = flash
  highlights.Visual = "VisualYankFlash"
  vim.opt_local.winhighlight = highlights

  vim.defer_fn(function()
    if visual_flashes[win] ~= flash then
      return
    end
    visual_flashes[win] = nil
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_call(win, function()
        local current = vim.opt_local.winhighlight:get()
        if current.Visual == "VisualYankFlash" then
          current.Visual = flash.original
          vim.opt_local.winhighlight = current
        end
      end)
    end
  end, 1000)
end

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("highlight-yank", {} --[[ { clear = true } ]]),
  callback = function()
    if vim.v.event.operator == "y" and vim.v.event.visual then
      if vim.fn.reg_executing() == "" then
        flash_visual_yank()
      end
      return
    end
    vim.hl.hl_op {
      higroup = "IncSearch",
      timeout = 600,
    }
  end,
})
