local M = {}
local api = vim.api
local attached = {}
local queued = false

local function update()
  -- Preview handles are returned with "selected" on this Neovim version;
  -- asking for "preview_winid" alone silently returns an empty dictionary.
  local info = vim.fn.complete_info { "selected", "completed" }
  local win, buf = info.preview_winid, info.preview_bufnr
  if
    not win
    or not api.nvim_win_is_valid(win)
    or not buf
    or not api.nvim_buf_is_valid(buf)
  then
    return
  end
  vim.wo[win].winhighlight =
    "Normal:PmenuPreview,NormalFloat:PmenuPreview,FloatBorder:PmenuPreviewBorder"
  local border = api.nvim_win_get_config(win).border
  if type(border) ~= "table" or border[1] ~= "╭" then
    api.nvim_win_set_config(win, { border = "rounded" })
  end

  if not attached[buf] then
    attached[buf] = true
    -- completionItem/resolve can replace the text without CompleteChanged.
    api.nvim_buf_attach(buf, false, {
      on_lines = M.schedule,
      on_detach = function()
        attached[buf] = nil
      end,
    })
  end

  local lsp = vim.tbl_get(info, "completed", "user_data", "nvim", "lsp")
  local markdown = vim.treesitter.highlighter.active[buf] ~= nil
    or (lsp and lsp.info_kind == "markdown")
  local ok = pcall(require, "render-markdown")
  if ok then
    if markdown then
      vim.treesitter.start(buf, "markdown")
    end
    local config = require("render-markdown.state").get(buf, {
      render_modes = true,
      debounce = 0,
    })
    -- The popup reuses its buffer for Markdown and plaintext candidates.
    config.enabled = not not markdown
    -- The public render API also attaches its completion LSP to the current
    -- source buffer. Only update decorations in this documentation window.
    require("render-markdown.core.ui").update(buf, win, "Completion", true)
  end
end

function M.schedule()
  if queued then
    return
  end
  queued = true
  vim.schedule(function()
    queued = false
    update()
  end)
end

return M
