local function parse_java_opts(opts_string)
  local result = {}

  -- Handle empty or nil input
  if not opts_string or opts_string == "" then
    return result
  end

  -- Split by spaces first to get individual options
  for opt in opts_string:gmatch "%S+" do
    -- Check if the option contains '='
    local key, value = opt:match "^(.-)=(.*)$"

    if key and value then
      -- Option has key=value format
      table.insert(result, key)
      table.insert(result, value)
    else
      -- Option doesn't have '=' (standalone option)
      table.insert(result, opt)
    end
  end

  return result
end

local function create_config()
  local metals_config = require("metals").bare_config()

  local success, server_props = pcall(parse_java_opts, vim.fn.getenv "METALS_JAVA_OPTS")
  metals_config.settings = {
    showImplicitArguments = true,
    excludedPackages = { "akka.actor.typed.javadsl", "com.github.swagger.akka.javadsl" },
  }
  if server_props and success then
    local coursier_creds = vim.fn.getenv "COURSIER_CREDENTIALS"
    if coursier_creds then
      table.insert(server_props, "-Dcoursier.credentials")
      table.insert(server_props, coursier_creds)
    end
    vim.print(server_props)
    metals_config.settings.serverProperties = server_props
  end
  metals_config.init_options.statusBarProvider = "off"

  -- Example if you are using cmp how to make sure the correct capabilities for snippets are set
  metals_config.capabilities = require("cmp_nvim_lsp").default_capabilities()

  metals_config.on_attach = function(client, bufnr)
    require("metals").setup_dap()
  end

  return metals_config
end

return function(self, _)
  local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    pattern = self.ft,
    callback = function()
      require("metals").initialize_or_attach(create_config())
    end,
    group = nvim_metals_group,
  })
end
