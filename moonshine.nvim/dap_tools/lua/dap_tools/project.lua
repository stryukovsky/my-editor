local M = {}

function M.root()
  local projects = require "moonshine.projects"
  local cwd = projects.current_root() or vim.fn.getcwd()
  return projects.tab_project() or vim.fs.root(cwd, ".git") or cwd
end

function M.files(root)
  local cmd = {
    "rg",
    "--files",
    "--hidden",
    "--no-ignore",
    "--glob",
    "!.git",
    "--glob",
    "!node_modules",
    "--glob",
    "!target",
    "--glob",
    "!.venv",
    "--glob",
    "!venv",
    "--glob",
    "!data",
    "--glob",
    "!vendor",
  }
  local markers = {}
  for _, entry in ipairs(require("dap_tools.catalog").entries) do
    for _, marker in ipairs(entry.markers) do
      markers[marker] = true
    end
  end
  for marker in pairs(markers) do
    vim.list_extend(cmd, { "--glob", marker })
  end
  local result = vim.system(cmd, { cwd = root, text = true }):wait(2000)
  if result.code ~= 0 and result.code ~= 1 then
    error("Cannot inspect project markers: " .. (result.stderr or "rg failed"))
  end
  return vim.split(result.stdout or "", "\n", { trimempty = true })
end

function M.rank(root, files)
  files = vim.deepcopy(files)
  table.sort(files)
  local entries = {}
  for _, definition in ipairs(require("dap_tools.catalog").entries) do
    local entry = vim.deepcopy(definition)
    entry.matches = {}
    local depth
    for _, path in ipairs(files) do
      if vim.tbl_contains(entry.markers, vim.fs.basename(path)) then
        entry.matches[#entry.matches + 1] = path
        local _, nesting = path:gsub("/", "")
        if not depth or nesting < depth then
          depth = nesting
          entry.root = vim.fs.dirname(vim.fs.joinpath(root, path))
        end
      end
    end
    table.sort(entry.matches)
    entry.score = depth and math.max(1, 10000 - depth * 100 + #entry.matches)
      or 0
    entry.root = entry.root or root
    entries[#entries + 1] = entry
  end
  table.sort(entries, function(a, b)
    if a.score ~= b.score then
      return a.score > b.score
    end
    return a.name < b.name
  end)
  return entries
end

return M
