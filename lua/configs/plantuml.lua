local M = {}

function M.visualize(lines)
  if not lines or #lines == 0 then
    vim.notify("No lines to visualize", vim.log.levels.ERROR)
    return
  end

  local input = table.concat(lines, "\n") .. "\n"

  local result = vim
    .system({ "plantuml", "-utxt", "-p" }, {
      text = true,
      stdin = input,
    })
    :wait()

  if result.code ~= 0 then
    vim.notify("plantuml failed: " .. ((result.stderr or "exit code ") .. result.code), vim.log.levels.ERROR)
    return
  end

  local output = result.stdout
  if not output or #output == 0 then
    vim.notify("plantuml produced no output", vim.log.levels.WARN)
    return
  end

  local out_lines = vim.split(output, "\n", { plain = true })

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, out_lines)

  vim.bo[buf].modifiable = false

  -- vim.cmd "split"
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.wo[win].wrap = false

  local ok, name = pcall(vim.api.nvim_buf_set_name, buf, "plantuml-ascii")
  if not ok then
    vim.api.nvim_buf_set_name(buf, "plantuml-ascii-" .. math.random(9999))
  end
end

return M

