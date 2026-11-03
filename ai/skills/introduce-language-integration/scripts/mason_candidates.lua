-- Read-only discovery against this repository's installed Mason and registry.
-- Usage: nvim --headless -u NONE -i NONE -l <this-file> <Mason-language> [category]
local function fail(message)
  io.stderr:write(message .. "\n")
  vim.cmd "cquit 1"
end

local script = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")
local root = vim.fs.dirname(script)
for _ = 1, 4 do
  root = vim.fs.dirname(root)
end
local query, category = arg[1], arg[2]
if not query or arg[3] or (query == "--languages" and category) then
  fail "Usage: mason_candidates.lua <Mason-language> [category] | --languages"
end

vim.opt.runtimepath:prepend(root .. "/data/lazy/mason.nvim")
local ok, registry = pcall(function()
  require("mason").setup { install_root_dir = root .. "/data/mason" }
  return require "mason-registry"
end)
if not ok then
  fail("Cannot load installed Mason: " .. tostring(registry))
end
local specs_ok, specs = pcall(registry.get_all_package_specs)
if not specs_ok or #specs == 0 then
  fail "Mason registry unavailable or empty. Refresh it in Neovim with :MasonUpdate, then retry."
end

local function contains(values, target)
  for _, value in ipairs(values or {}) do
    if value:lower() == target:lower() then
      return true
    end
  end
  return false
end

local languages, matches = {}, {}
for _, spec in ipairs(specs) do
  for _, language in ipairs(spec.languages or {}) do
    languages[language] = true
  end
  if contains(spec.languages, query) and (not category or contains(spec.categories, category)) then
    local executables = vim.tbl_keys(spec.bin or {})
    table.sort(executables)
    matches[#matches + 1] = {
      package = spec.name,
      categories = spec.categories,
      languages = spec.languages,
      executables = executables,
      installed = registry.is_installed(spec.name),
      lspconfig = spec.neovim and spec.neovim.lspconfig or nil,
      homepage = spec.homepage,
    }
  end
end
if query == "--languages" then
  local names = vim.tbl_keys(languages)
  table.sort(names)
  print(vim.json.encode(names))
else
  table.sort(matches, function(a, b)
    return a.package < b.package
  end)
  print(vim.json.encode {
    source = "installed Mason cached registry; not refreshed by this command",
    language = query,
    category = category,
    candidates = matches,
    note = #matches == 0 and "No cached matches; verify language label, category, registry freshness and shared tools." or nil,
  })
end
