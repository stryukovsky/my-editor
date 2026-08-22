local actions = require "telescope.actions"
local wrap_telescope_action = require "mappings.telescope_action_wrapper"

local HINTS = {
  { "<cr>", "switch to this picked branch" },
  { "m", "merge this picked branch into current git branch" },
  { "d", "delete branch" },
  { "r", "rebase current git branch on top of this picked branch" },
  { "?", "toggle this help off" },
}

---@type integer|nil
local help_win

local function close_help()
  if help_win and vim.api.nvim_win_is_valid(help_win) then
    vim.api.nvim_win_close(help_win, true)
  end
  help_win = nil
end

-- Overlay only — do not enter the float, or Telescope closes the picker.
local function help()
  if help_win and vim.api.nvim_win_is_valid(help_win) then
    close_help()
    return
  end

  local key_width = 0
  for _, row in ipairs(HINTS) do
    key_width = math.max(key_width, vim.fn.strdisplaywidth(row[1]))
  end

  local lines = {}
  for _, row in ipairs(HINTS) do
    local pad = string.rep(" ", key_width - vim.fn.strdisplaywidth(row[1]))
    lines[#lines + 1] = string.format(" %s%s  %s ", row[1], pad, row[2])
  end

  local width = 16
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false

  local height = #lines
  help_win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " Git branches ",
    title_pos = "center",
    zindex = 200,
    focusable = false,
    noautocmd = true,
  })

  local ns = vim.api.nvim_create_namespace "pretty_git_branch_help"
  for i, row in ipairs(HINTS) do
    pcall(vim.hl.range, buf, ns, "TelescopeResultsIdentifier", { i - 1, 1 }, { i - 1, 1 + #row[1] })
  end

  vim.api.nvim_create_autocmd({ "BufLeave", "WinClosed" }, {
    buffer = vim.api.nvim_get_current_buf(),
    once = true,
    callback = close_help,
  })
end

return {
  ["<cr>"] = wrap_telescope_action(actions.git_switch_branch),
  d = wrap_telescope_action(actions.git_delete_branch),
  m = wrap_telescope_action(actions.git_merge_branch),
  r = wrap_telescope_action(actions.git_rebase_branch),
  ["?"] = function()
    help()
  end,
}
