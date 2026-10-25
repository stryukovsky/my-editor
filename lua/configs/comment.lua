---@diagnostic disable: missing-fields
local ft = require "Comment.ft"
ft.set("solidity", { "//%s", "/*%s*/" })
local shell_filetypes =
  { sh = true, bash = true, zsh = true, env = true, dotenv = true }
for _, filetype in ipairs { "sh", "bash", "zsh", "env", "dotenv" } do
  ft.set(filetype, "#%s")
end
local blockwise_comment = require("Comment.utils").ctype.blockwise
require("Comment").setup {
  ---@return string|nil
  pre_hook = function(ctx)
    local filetype = vim.bo.filetype
    if filetype == "solidity" then
      return ctx.ctype == blockwise_comment and "/*%s*/" or "//%s"
    end
    if shell_filetypes[filetype] then
      return "#%s"
    end
    return nil
  end,
}
