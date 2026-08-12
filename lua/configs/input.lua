local M = {}
local map = require "mappings.map"

local function display_width(text)
  return vim.fn.strdisplaywidth(text)
end

function M.setup()
  vim.ui.input = function(opts, on_confirm)
    opts = opts or {}
    on_confirm = on_confirm or function() end
    local prompt = opts.prompt or "Input"
    local default = opts.default == nil and "" or tostring(opts.default)
    local max_width = math.max(1, vim.o.columns - 4)
    local width = math.min(max_width, math.max(40, display_width(default) + 4))
    local height = 1
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    local buffer = vim.api.nvim_create_buf(false, true)
    local completed = false

    vim.bo[buffer].bufhidden = "wipe"
    vim.bo[buffer].buftype = "nofile"
    vim.bo[buffer].swapfile = false
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { default })

    local window = vim.api.nvim_open_win(buffer, true, {
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      style = "minimal",
      border = "rounded",
      title = prompt,
      title_pos = "center",
      zindex = 60,
    })

    local function finish(value)
      if completed then
        return
      end
      completed = true

      if vim.api.nvim_win_is_valid(window) then
        vim.api.nvim_win_close(window, true)
      end

      vim.schedule(function()
        on_confirm(value)
      end)
    end

    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(window),
      once = true,
      callback = function()
        finish(nil)
      end,
    })

    map({ "i", "n" }, "<CR>", function()
      finish(vim.api.nvim_get_current_line())
    end, { buffer = buffer, nowait = true })
    local cancel = function()
      finish(nil)
    end
    map("n", "q", cancel, { buffer = buffer, nowait = true })
    map("n", "<Esc>", cancel, { buffer = buffer, nowait = true })

    vim.cmd "startinsert"
  end

  vim.input = vim.ui.input
end

return M
