local M = {}

function M.filter(prompt)
  local pattern = prompt:match "^(.-)%s+%-re%s*$"
  if pattern then
    return { prompt = pattern }
  end
  -- Escape regex syntax so ripgrep treats the request as literal text.
  return { prompt = vim.fn.escape(prompt, [[\.^$*+?()[]{}|]]) }
end

function M.open(opts)
  opts = vim.tbl_extend("force", opts or {}, {
    prompt_title = "Global search — add -re at the end for regex",
    on_input_filter_cb = M.filter,
  })
  require("telescope.builtin").live_grep(opts)
end

function M.visual()
  local saved = vim.fn.getreginfo "v"
  vim.cmd [[noautocmd silent normal! "vy]]
  local selection = vim.fn.getreg "v"
  vim.fn.setreg("v", saved)
  M.open { default_text = selection }
end

return M
