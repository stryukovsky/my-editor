local M = {}
local running = {}
local min_duration_ns = 1000 * 1e6

function M.setup(opts)
  min_duration_ns = opts.min_duration_ms * 1e6
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = vim.api.nvim_create_augroup(
      "TerminalCompletionNotifications",
      { clear = true }
    ),
    callback = function(event)
      running[event.buf] = nil
    end,
  })
end

function M.observe(buf, label, process)
  local now = vim.uv.hrtime()
  local previous = running[buf]
  if previous and not vim.uv.fs_stat("/proc/" .. previous.pid) then
    running[buf] = nil
    if
      now - previous.started > min_duration_ns
      and vim.fn.executable "notify-send" == 1
    then
      vim.fn.jobstart({
        "notify-send",
        "--app-name=Neovim",
        "--icon=utilities-terminal",
        "--",
        previous.label .. " finished",
        "Terminal command finished in Neovim.",
      }, { detach = true })
    end
  end
  if
    process
    and process.active
    and (not running[buf] or running[buf].pid ~= process.pid)
  then
    running[buf] = { pid = process.pid, label = label, started = now }
  end
end

return M
