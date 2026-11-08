local M = {}

-- A mode label avoids changing terminal or window colors.
function M.mode_label()
  local win = vim.g.statusline_winid
  local active = win == vim.api.nvim_get_current_win()
    and vim.api.nvim_get_mode().mode == "t"
  if active then
    return "%#TerminalInputBar# press <esc> to leave terminal, press <C-Esc> to send esc to process inside %= "
  end
  return "%#TerminalNormalBar# press 'i' to enter terminal %= "
end

function M.setup()
  local terminal_winbar = "%!v:lua.require'terminal_reimagined'.mode_label()"
  vim.api.nvim_create_autocmd({
    "ModeChanged",
    "BufWinEnter",
    "WinEnter",
    "TermOpen",
    "TermEnter",
    "TermLeave",
  }, {
    group = vim.api.nvim_create_augroup(
      "TerminalModeIndicator",
      { clear = true }
    ),
    callback = function(event)
      -- Insert completion submodes do not change the terminal indicator. A forced
      -- redraw there exposes the temporarily removed completion prefix in inputs.
      if
        event.event == "ModeChanged"
        and vim.v.event.old_mode ~= "t"
        and vim.v.event.new_mode ~= "t"
      then
        return
      end
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local terminal = vim.bo[vim.api.nvim_win_get_buf(win)].buftype
          == "terminal"
        if terminal then
          if vim.w[win].terminal_original_winbar == nil then
            vim.w[win].terminal_original_winbar = vim.wo[win].winbar
                  == terminal_winbar
                and ""
              or vim.wo[win].winbar
          end
          vim.wo[win].winbar = terminal_winbar
        elseif vim.w[win].terminal_original_winbar ~= nil then
          if
            vim.wo[win].winbar == terminal_winbar or vim.wo[win].winbar == ""
          then
            vim.wo[win].winbar = vim.w[win].terminal_original_winbar
          end
          vim.w[win].terminal_original_winbar = nil
        elseif vim.wo[win].winbar == terminal_winbar then
          vim.wo[win].winbar = ""
        end
      end
      vim.cmd "redrawstatus"
    end,
  })

  -- Embedded terminals consume OSC requests instead of passing them to the host.
  -- Forward notification protocols so Kitty/Ghostty can show desktop alerts.
  vim.api.nvim_create_autocmd("TermRequest", {
    group = vim.api.nvim_create_augroup(
      "TerminalDesktopNotifications",
      { clear = true }
    ),
    callback = function(event)
      local data = event.data
      local sequence = data and data.sequence or vim.v.termrequest
      if not sequence then
        return
      end
      if
        sequence:match "^\027%]9;"
        or sequence:match "^\027%]99;"
        or sequence:match "^\027%]777;notify;"
      then
        vim.api.nvim_ui_send(sequence .. (data and data.terminator or "\027\\"))
      end
    end,
  })
end

return M
