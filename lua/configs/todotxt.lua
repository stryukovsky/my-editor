---@diagnostic disable: missing-fields
local function directory_for_todotxt()
  local home = vim.env.HOME
  local work_dir = home .. "/Work/my-vault/"

  if vim.fn.isdirectory(work_dir) == 1 then
    return work_dir
  else
    return home .. "/Documents/"
  end
end

require("todotxt").setup {
  lsp = true,
  todotxt = directory_for_todotxt() .. "todo.todotxt",
  donetxt = directory_for_todotxt() .. "done.todotxt",
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

vim.api.nvim_set_hl(0, "TodoPriorityA", { bg = "#e06c75", fg = "#ffffff", bold = true })
vim.api.nvim_set_hl(0, "TodoPriorityB", { bg = "#d19a66", fg = "#ffffff", bold = true })
vim.api.nvim_set_hl(0, "TodoPriorityC", { bg = "#98c379", fg = "#ffffff", bold = true })
vim.api.nvim_set_hl(0, "TodoDoneTask", { strikethrough = true })

local ns = vim.api.nvim_create_namespace "todotxt-project-highlights"

local function apply_project_highlights(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "todotxt" then
    return
  end

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local ok, parser = pcall(vim.treesitter.get_parser, buf, "todotxt")
  if not ok or not parser then
    return
  end

  local tree = parser:parse()
  if not tree or vim.tbl_isempty(tree) then
    return
  end

  local query = vim.treesitter.query.parse("todotxt", "(project) @project (priority) @priority")

  local project_map = {}
  local color_count = 0

  for _, node in query:iter_captures(tree[1]:root(), buf, 0, -1) do
    local t = node:type()
    if t == "project" then
      local project = vim.treesitter.get_node_text(node, buf)
      if project then
        local pname = project:sub(2)
        if not project_map[pname] then
          color_count = color_count + 1
          project_map[pname] = ((color_count - 1) % #project_colors) + 1
        end
        local start_row, start_col, _, end_col = node:range()
        vim.api.nvim_buf_set_extmark(buf, ns, start_row, start_col, {
          end_col = end_col,
          hl_group = "TodoProject" .. project_map[pname],
        })
      end
    elseif t == "priority" then
      local text = vim.treesitter.get_node_text(node, buf)
      if text == "(A)" or text == "(B)" or text == "(C)" then
        local start_row, start_col, _, end_col = node:range()
        vim.api.nvim_buf_set_extmark(buf, ns, start_row, start_col, {
          end_col = end_col,
          hl_group = "TodoPriority" .. text:sub(2, 2),
        })
      end
    end
  end

  for i = 0, vim.api.nvim_buf_line_count(buf) - 1 do
    local line = vim.api.nvim_buf_get_lines(buf, i, i + 1, false)[1]
    if line and line:sub(1, 2) == "x " then
      vim.api.nvim_buf_set_extmark(buf, ns, i, 0, {
        end_row = i,
        end_col = #line,
        hl_group = "TodoDoneTask",
        hl_mode = "combine",
      })
    end
  end
end

local debounce_timer

local function schedule_highlights(buf)
  if debounce_timer then
    pcall(debounce_timer.close, debounce_timer)
  end
  debounce_timer = vim.defer_fn(function()
    debounce_timer = nil
    apply_project_highlights(buf)
  end, 50)
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "todotxt",
  callback = function(ev)
    local buf = ev.buf
    vim.schedule(function()
      apply_project_highlights(buf)
    end)
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      buffer = buf,
      callback = function()
        schedule_highlights(buf)
      end,
    })
  end,
})
