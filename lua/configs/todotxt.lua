require("todotxt").setup {
  lsp = true,
  todotxt = vim.env.HOME .. "/Documents/todo.txt",
  donetxt = vim.env.HOME .. "/Documents/done.txt",
  max_priority = "C",
  metadata = {
    tag = { sort = "asc" },
    due = { sort = "desc" },
    effort = {
      sort = function(a, b)
        return tonumber(a) < tonumber(b)
      end,
    },
  },
  ghost_text = {
    enable = true,
    mappings = {
      ["(A)"] = "URGENT",
      ["(B)"] = "NORMAL",
      ["(C)"] = "FREE",
    },
  },
}

  local project_colors = {
    "#c678dd",
    "#e06c75",
    "#98c379",
    "#56b6c2",
    "#d19a66",
    "#61afef",
    "#e5c07b",
  }

for i, color in ipairs(project_colors) do
  vim.api.nvim_set_hl(0, "TodoProject" .. i, { fg = color, bold = true })
end

local ns = vim.api.nvim_create_namespace("todotxt-project-highlights")

local function apply_project_highlights()
  local buf = vim.api.nvim_get_current_buf()
  if not buf or vim.bo[buf].filetype ~= "todotxt" then return end

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local ok, parser = pcall(vim.treesitter.get_parser, buf, "todotxt")
  if not ok or not parser then return end

  local tree = parser:parse()
  if not tree or vim.tbl_isempty(tree) then return end

  local query = vim.treesitter.query.parse("todotxt", "(project) @project")

  local project_map = {}
  local color_count = 0

  for _, node in query:iter_captures(tree[1]:root(), buf, 0, -1) do
    local project = vim.treesitter.get_node_text(node, buf)
    if project then
      local name = project:sub(2)
      if not project_map[name] then
        color_count = color_count + 1
        project_map[name] = ((color_count - 1) % #project_colors) + 1
      end
      local start_row, start_col, _, end_col = node:range()
      vim.api.nvim_buf_add_highlight(buf, ns, "TodoProject" .. project_map[name], start_row, start_col, end_col)
    end
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "todotxt",
  callback = function(ev)
    vim.schedule(apply_project_highlights)
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      buffer = ev.buf,
      callback = apply_project_highlights,
    })
  end,
})
