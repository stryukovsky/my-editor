local M = {}

M.config = {
  modes = {
    git_commit_files = {
      desc = "Files affected by a Git commit",
      source = "git_commit_files",
      title = "{hl:Title} Commit files{hl}  {count} files",
      format = "{file_icon} {filename}",
      sort = { "filename" },
      focus = true,
      follow = false,
      auto_preview = false,
      keys = { ["<cr>"] = "jump" },
    },
  },
}

function M.get(cb, ctx)
  local Item = require "trouble.item"
  local items = {}
  for _, filename in ipairs(ctx.opts.commit_files or {}) do
    items[#items + 1] =
      Item.new { filename = filename, source = "git_commit_files" }
  end
  Item.add_id(items)
  cb(items)
end

return M
