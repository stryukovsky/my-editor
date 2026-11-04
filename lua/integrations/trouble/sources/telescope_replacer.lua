local M = {}

local function review()
  return require "telescope_pretty_picker.replacer_review"
end

local function replacement_preview(ctx)
  local match = ctx.item.item
  local replacement = ctx.item.replacement
  local removed = match.line:sub(match.start + 1, match.stop)
  local separator = removed ~= "" and replacement ~= "" and " → " or ""
  return {
    { text = vim.fn.strtrans(match.line:sub(1, match.start)) },
    { text = vim.fn.strtrans(removed), hl = "DiffDelete" },
    { text = separator },
    { text = vim.fn.strtrans(replacement), hl = "DiffAdd" },
    { text = vim.fn.strtrans(match.line:sub(match.stop + 1)) },
  }
end

M.config = {
  modes = {
    telescope_replacer = {
      desc = "Preview ripgrep replacements",
      source = "telescope_replacer",
      title = "{hl:Title} Replace{hl} {hl:Comment}| r - one entry | R - all{hl}  {count} remaining",
      format = "{pos} {replacement_preview}",
      formatters = { replacement_preview = replacement_preview },
      groups = { "filename" },
      sort = { "filename", "pos" },
      focus = true,
      follow = false,
      restore = false,
      auto_preview = false,
      auto_refresh = false,
      keys = {
        ["<cr>"] = "jump",
        r = false,
        R = false,
      },
    },
  },
}

function M.get(cb)
  cb(review().items())
end

return M
