local M = {}
local sessions = {}

local function finish(session, accept)
  if session.finished then
    return
  end
  session.finished = true
  sessions[session.path] = nil
  vim.fn.writefile({ accept and "0" or "1" }, session.done)
  if vim.api.nvim_buf_is_valid(session.buf) then
    vim.api.nvim_buf_delete(session.buf, { force = true })
  end
  if vim.api.nvim_win_is_valid(session.source_win) then
    vim.api.nvim_set_current_win(session.source_win)
    if vim.bo.buftype == "terminal" then
      vim.cmd.startinsert()
    end
  end
end

function M.cancel(opts)
  local session = sessions[opts.path]
  if session then
    finish(session, false)
  end
  return true
end

function M.open(opts)
  if sessions[opts.path] then
    return true
  end
  local source_win = vim.api.nvim_get_current_win()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.b[buf].terminal_job_pid == opts.shell_pid then
      local win = vim.fn.bufwinid(buf)
      if win ~= -1 then
        source_win = win
      end
      break
    end
  end
  vim.cmd.stopinsert()
  local buf = vim.api.nvim_create_buf(true, true)
  local session = {
    path = opts.path,
    done = opts.done,
    buf = buf,
    source_win = source_win,
    saved = false,
  }
  sessions[opts.path] = session
  vim.b[buf].terminal_command = true
  vim.b[buf].terminal_command_cwd = opts.cwd
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].undofile = false
  vim.api.nvim_buf_set_name(buf, "Command line " .. buf .. ".zsh")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.fn.readfile(opts.path))
  vim.bo[buf].modified = false
  local width = math.max(1, math.min(100, vim.o.columns - 4))
  local height = math.max(1, math.min(12, vim.o.lines - 6))
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    border = "rounded",
    title = " Command line · Ctrl-S apply · Ctrl-Q cancel ",
    title_pos = "center",
  })
  vim.cmd("lcd " .. vim.fn.fnameescape(opts.cwd))
  vim.bo[buf].filetype = "sh"
  local ok, config = pcall(function()
    return vim.lsp.config.bashls
  end)
  if
    ok
    and config
    and type(config.cmd) == "table"
    and vim.fn.executable(config.cmd[1]) == 1
  then
    config = vim.tbl_deep_extend(
      "force",
      {},
      config,
      { name = "bashls", root_dir = opts.cwd }
    )
    vim.lsp.start(config, { bufnr = buf })
  end
  vim.wo.wrap = true
  vim.wo.number = true
  local function save()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local result = vim.fn.writefile(lines, opts.path)
    if result ~= 0 then
      error "Could not save command line"
    end
    vim.bo[buf].modified = false
    session.saved = true
  end
  vim.api.nvim_create_autocmd("BufWriteCmd", { buffer = buf, callback = save })
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      -- Defer out of buffer teardown before restoring the source terminal window.
      vim.schedule(function()
        finish(session, session.saved)
      end)
    end,
  })
  local map = require "mappings.map"
  map({ "n", "i" }, "<C-s>", function()
    save()
    finish(session, true)
  end, { buffer = buf, desc = "Return command to shell" })
  map({ "n", "i" }, "<C-q>", function()
    finish(session, false)
  end, { buffer = buf, desc = "Cancel command editing" })
  -- edit-command-line supplies a 1-based byte offset, including multiline input.
  local remaining = math.max(0, (opts.offset or 1) - 1)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for row, line in ipairs(lines) do
    if remaining <= #line or row == #lines then
      vim.api.nvim_win_set_cursor(0, { row, math.min(remaining, #line) })
      break
    end
    remaining = remaining - #line - 1
  end
  return true
end

return M
