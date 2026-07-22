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
  if not buf or vim.bo[buf].filetype ~= "todotxt" then
    return
  end

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local project_map = {}
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  for lnum, line in ipairs(lines) do
    for project in line:gmatch("%f[%w+]%+([%w_]+)") do
      if not project_map[project] then
        project_map[project] = (#project_map % #project_colors) + 1
      end
      vim.api.nvim_buf_add_highlight(buf, ns, "TodoProject" .. project_map[project], lnum - 1, 0, -1)
      break
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
