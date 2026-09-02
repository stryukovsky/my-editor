local notify = require "configs.notify"

local M = {}

---@return boolean
function M.is_ghostty()
  return vim.env.TERM_PROGRAM == "ghostty" or vim.env.TERM == "xterm-ghostty"
end

---@return boolean
function M.is_kitty()
  local listen_on = vim.env.KITTY_LISTEN_ON
  return (type(listen_on) == "string" and listen_on ~= "") or vim.env.TERM == "xterm-kitty"
end

---@param cwd string
---@param opts? { source?: string, tab_title?: string, argv?: string[] }
---@return boolean
function M.open(cwd, opts)
  if not cwd or cwd == "" then
    notify.send("Terminal", "No working directory provided", vim.log.levels.WARN)
    return false
  end

  if M.is_ghostty() then
    vim.fn.jobstart({ "ghostty", "--working-directory=" .. cwd }, { detach = true })
    return true
  end

  if M.is_kitty() then
    return require("configs.kitten").launch {
      type = "tab",
      cwd = cwd,
      tab_title = opts and opts.tab_title,
      -- Use an interactive login shell so aliases/functions from .zshrc resolve,
      -- then retain a terminal after Neovim exits.
      argv = opts and opts.argv or { "zsh", "--login", "-i", "-c", "nvim; exec zsh --login -i" },
    }
  end

  notify.send(opts and opts.source or "Terminal", "Open a terminal from Ghostty or Kitty first", vim.log.levels.WARN)
  return false
end

return M
