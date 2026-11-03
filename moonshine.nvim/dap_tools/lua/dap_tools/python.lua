local M = {}

function M.find(root)
  for _, relative in ipairs { ".venv/bin/python", "venv/bin/python" } do
    local python = vim.fs.joinpath(root, relative)
    if vim.fn.executable(python) == 1 then
      return python
    end
  end
end

function M.activate(root)
  local python = M.find(root) or vim.fn.exepath "python3"
  local adapter = vim.fn.exepath "debugpy-adapter"
  if adapter == "" then
    local mason = vim.fn.stdpath "data"
      .. "/mason/packages/debugpy/venv/bin/python"
    adapter = vim.fn.executable(mason) == 1 and mason or python
    if adapter == "" then
      error "Python is not installed"
    end
    local result = vim
      .system({ adapter, "-c", "import debugpy" }, { text = true })
      :wait(3000)
    if result.code ~= 0 then
      error "debugpy is missing; install it with :MasonInstall debugpy or in the project virtualenv"
    end
  end
  require("dap-python").setup(adapter, { include_configs = false })
  if python ~= "" then
    require("dap-python").resolve_python = function()
      return M.find(vim.fn.getcwd()) or python
    end
    for _, name in ipairs { "basedpyright", "pyright" } do
      pcall(
        vim.lsp.config,
        name,
        { settings = { python = { pythonPath = python } } }
      )
      for _, client in ipairs(vim.lsp.get_clients { name = name }) do
        if client.config.root_dir == root then
          client.settings = vim.tbl_deep_extend(
            "force",
            client.settings or {},
            { python = { pythonPath = python } }
          )
          client:notify(
            "workspace/didChangeConfiguration",
            { settings = client.settings }
          )
        end
      end
    end
  end
end

return M
