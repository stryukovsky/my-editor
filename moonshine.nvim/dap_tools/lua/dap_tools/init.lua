local M = { active = {} }

local function install_configurations(entry)
  local dap = require "dap"
  for ft, configs in pairs(require("dap_tools.catalog").configurations(entry)) do
    dap.configurations[ft] = dap.configurations[ft] or {}
    for _, config in ipairs(configs) do
      local exists = false
      for _, existing in ipairs(dap.configurations[ft]) do
        exists = exists
          or (existing.name == config.name and existing.type == config.type)
      end
      if not exists then
        table.insert(dap.configurations[ft], config)
      end
    end
  end
end

function M.activate(id, context)
  local entry = require("dap_tools.catalog").get(id)
  context = context
    or {
      root = require("dap_tools.project").root(),
      bufnr = vim.api.nvim_get_current_buf(),
    }
  local dap = require "dap"
  local ok, err = pcall(function()
    if entry.command and vim.fn.executable(entry.command) ~= 1 then
      error("Missing debug adapter executable: " .. entry.command)
    end
    if id == "python" then
      require("dap_tools.python").activate(context.root)
    elseif id == "javascript" then
      dap.adapters.node = vim.deepcopy(require("dap_tools.presets").node)
      dap.adapters["pwa-node"] = dap.adapters.node
    elseif id == "cpp" or id == "rust" then
      dap.adapters.codelldb =
        vim.deepcopy(require("dap_tools.presets").codelldb)
    elseif id == "go" then
      local previous = dap.configurations.go
      require("dap-go").setup()
      dap.configurations.go = previous
    elseif id == "java" then
      require("jdtls").setup_dap {
        hotcodereplace = "auto",
        config_overrides = { cwd = "${workspaceFolder}" },
      }
      -- dap_tools supplies presets; jdtls supplies the launch transport/enrichment.
      dap.providers.configs.jdtls = nil
    elseif id == "scala" then
      require("metals").setup_dap()
    end
    install_configurations(entry)
  end)
  if not ok then
    require("integrations.notify").send(
      "DAP activation",
      tostring(err),
      vim.log.levels.ERROR
    )
    return false
  end
  M.active[id] = true
  require("integrations.notify").send(
    "DAP activation",
    entry.name .. ": activated"
  )
  return true
end

function M.setup()
  require("dap_tools.env_file").setup()
end

function M.open()
  return require("dap_tools.picker").open()
end

return M
