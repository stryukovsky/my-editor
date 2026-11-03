local lib = require "neotest.lib"

---@type neotest.Adapter
local adapter = { name = "neotest-forge" }

local query = [[
  (contract_declaration
    name: (identifier) @namespace.name) @namespace.definition

  (function_definition
    name: (identifier) @test.name
    (#match? @test.name "^(test|invariant|statefulFuzz)")) @test.definition
]]

function adapter.root(path)
  return vim.fs.root(path, "foundry.toml")
end

function adapter.is_test_file(path)
  return path:match "%.t%.sol$" ~= nil
end

function adapter.filter_dir(name)
  return not vim.tbl_contains(
    { "lib", "out", "cache", ".git", "node_modules" },
    name
  )
end

function adapter.discover_positions(path)
  return lib.treesitter.parse_positions(path, query, {
    nested_tests = false,
    require_namespaces = true,
  })
end

function adapter.build_spec(args)
  if args.strategy == "dap" then
    error "Forge tests use Neotest's integrated runner; DAP is not supported"
  end

  local position = args.tree:data()
  local root = assert(
    adapter.root(position.path),
    "Cannot find foundry.toml for Forge tests"
  )
  local report = vim.fn.tempname() .. ".json"
  local command = {
    "forge",
    "test",
    "--root",
    root,
    "--json-file",
    report,
    "--color",
    "never",
    "-vvv",
  }
  local relative = vim.fs.relpath(root, position.path)
  if position.type == "dir" then
    if relative and relative ~= "." and relative ~= "" then
      vim.list_extend(command, { "--match-path", relative .. "/**" })
    end
  else
    vim.list_extend(command, { "--match-path", assert(relative) })
  end

  local namespace = args.tree
  while namespace and namespace:data().type ~= "namespace" do
    namespace = namespace:parent()
  end
  if namespace then
    vim.list_extend(
      command,
      { "--match-contract", "^" .. namespace:data().name .. "$" }
    )
  end
  if position.type == "test" then
    -- Forge matches the full signature, including fuzz-test parameters.
    vim.list_extend(command, { "--match-test", "^" .. position.name .. "\\(" })
  end
  vim.list_extend(command, args.extra_args or {})

  return {
    command = command,
    cwd = root,
    context = { report = report },
  }
end

adapter.results = require "neotest-forge.results"

return adapter
