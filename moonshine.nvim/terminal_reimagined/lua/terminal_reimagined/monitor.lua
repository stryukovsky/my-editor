local M = {}
local identity = require "terminal_reimagined.identity"

-- Foreground process groups distinguish an active command from the waiting shell.
local process_names = require "moonshine.utils.terminal_process_name"
local notifications = require "terminal_reimagined.notifications"
local timer
function M.setup(opts)
  if timer and not timer:is_closing() then
    timer:stop()
    timer:close()
  end
  timer = vim.uv.new_timer()
  timer:start(
    opts.initial_delay_ms,
    opts.interval_ms,
    vim.schedule_wrap(function()
      local changed = false
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if
          vim.api.nvim_buf_is_valid(buf)
          and vim.bo[buf].buftype == "terminal"
        then
          local label, process =
            process_names.current(vim.b[buf].terminal_job_pid)
          notifications.observe(buf, label, process)
          if
            vim.b[buf].terminal_auto_name
            and label
            and label ~= vim.b[buf].terminal_process_label
          then
            identity.set_auto(buf, label)
            changed = true
          end
        end
      end
      if changed then
        vim.cmd "redrawtabline"
      end
    end)
  )
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup(
      "TerminalProcessNames",
      { clear = true }
    ),
    callback = function()
      timer:stop()
      timer:close()
    end,
  })
end

return M
