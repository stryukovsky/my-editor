local width = 80

return function(title, prompt, action)
  local api = vim.api
  local buf = api.nvim_create_buf(false, true)
  local opts = { height = 1, style = "minimal", border = "single", row = 1, col = 1 }

  opts.relative, opts.width = "cursor", width
  opts.title, opts.title_pos = { { " " .. title .. " ", "@comment.danger" } }, "center"

  local win = api.nvim_open_win(buf, true, opts)
  vim.wo[win].winhl = "Normal:Normal,FloatBorder:Removed"
  api.nvim_set_current_win(win)

  api.nvim_buf_set_lines(buf, 0, -1, true, { prompt })

  vim.bo[buf].buftype = "prompt"
  vim.fn.prompt_setprompt(buf, "")
  vim.api.nvim_input "A"

  vim.keymap.set({ "i", "n" }, "<Esc>", "<cmd>q!<CR>", { buffer = buf })

  vim.fn.prompt_setcallback(buf, function(text)
    local providedValue = vim.trim(text)
    api.nvim_buf_delete(buf, { force = true })

    if #providedValue > 0 then
      action(providedValue)
    end
  end)
end
