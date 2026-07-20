local config_dir = vim.fn.stdpath "config"
local templates_dir = config_dir .. "/templates"
local index_path = templates_dir .. "/index.json"

local M = {}

function M.list()
  local ok, lines = pcall(vim.fn.readfile, index_path, "")
  if not ok or not lines or #lines == 0 then
    vim.notify("Templates index not found or invalid: " .. index_path, vim.log.levels.ERROR)
    return {}
  end
  local ok, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not ok or not data then
    vim.notify("Templates index not found or invalid: " .. index_path, vim.log.levels.ERROR)
    return {}
  end
  return data
end

function M.create(name)
  local templates = M.list()
  local template
  for _, t in ipairs(templates) do
    if t.name == name then
      template = t
      break
    end
  end
  if not template then
    vim.notify("Template not found: " .. name, vim.log.levels.ERROR)
    return
  end

  local src = templates_dir .. "/" .. template.path
  local dst = template.destination

  local src_ok, src_content = pcall(vim.fn.readfile, src, "")
  if not src_ok then
    vim.notify("Template file not found: " .. src, vim.log.levels.ERROR)
    return
  end

  local dst_dir = vim.fn.fnamemodify(dst, ":h")
  if vim.fn.isdirectory(dst_dir) == 0 then
    vim.fn.mkdir(dst_dir, "p")
  end

  local flags = vim.fn.filereadable(dst) == 1 and "a" or ""
  vim.fn.writefile(src_content, dst, flags)
  vim.notify(string.format("Template '%s' created at %s", name, dst), vim.log.levels.INFO)
end

function M.complete(arg_lead, _cmd_line, _cursor_pos)
  local templates = M.list()
  local results = {}
  for _, t in ipairs(templates) do
    if t.name:find(arg_lead, 1, true) == 1 then
      table.insert(results, t.name)
    end
  end
  return results
end

vim.api.nvim_create_user_command("Template", function(opts)
  M.create(opts.args)
end, {
  nargs = 1,
  complete = function(arg_lead, cmd_line, cursor_pos)
    return M.complete(arg_lead, cmd_line, cursor_pos)
  end,
  desc = "Create a file from a template",
})

return M