local notify = require "configs.notify"
local dap = require "dap"

local M = {}

local enabled = false
local FILETYPES = { scala = true, sbt = true }

local function open_readonly_file(path, filetype)
  if vim.fn.filereadable(path) ~= 1 then
    notify.send("Metals", string.format("File not found: %s", path), vim.log.levels.WARN)
    return
  end

  vim.cmd.edit(vim.fn.fnameescape(path))
  vim.bo.filetype = filetype
  vim.bo.readonly = true
  vim.bo.modifiable = false
end

local function parse_java_opts(opts_string)
  local result = {}
  if type(opts_string) ~= "string" or opts_string == "" then
    return result
  end

  for opt in opts_string:gmatch "%S+" do
    local key, value = opt:match "^(.-)=(.*)$"
    if key and value then
      table.insert(result, key)
      table.insert(result, value)
    else
      table.insert(result, opt)
    end
  end

  return result
end

local function env_string(name)
  local value = vim.fn.getenv(name)
  if type(value) ~= "string" or value == "" then
    return nil
  end
  return value
end

local function create_config()
  local metals_config = require("metals").bare_config()
  local success, server_props = pcall(parse_java_opts, env_string "METALS_JAVA_OPTS")
  metals_config.settings = {
    showImplicitArguments = true,
    excludedPackages = { "akka.actor.typed.javadsl", "com.github.swagger.akka.javadsl" },
  }
  if success and server_props then
    local coursier_creds = env_string "COURSIER_CREDENTIALS"
    if coursier_creds then
      table.insert(server_props, "-Dcoursier.credentials")
      table.insert(server_props, coursier_creds)
    end
    metals_config.settings.serverProperties = server_props
  end
  metals_config.init_options.statusBarProvider = "off"

  local ok_blink, blink = pcall(require, "blink.cmp")
  if ok_blink and blink.get_lsp_capabilities then
    metals_config.capabilities = blink.get_lsp_capabilities()
  end

  metals_config.on_attach = function()
    require("metals").setup_dap()

    -- scala
    dap.configurations.scala = {
      {
        type = "scala",
        request = "launch",
        name = "RunOrTest",
        metals = {
          runType = "runOrTestFile",
          --args = { "firstArg", "secondArg", "thirdArg" }, -- here just as an example
        },
      },
      {
        type = "scala",
        request = "launch",
        name = "Test Target",
        metals = {
          runType = "testTarget",
        },
      },
      {
        type = "scala",
        request = "launch",
        name = "Sbt run",
        metals = {
          shellCommand = "sbt run",
        },
      },
    }
  end

  return metals_config
end

---@param bufnr integer
local function attach_buf(bufnr)
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  if not FILETYPES[vim.bo[bufnr].filetype] then
    return
  end
  vim.api.nvim_buf_call(bufnr, function()
    require("metals").initialize_or_attach(create_config())
  end)
end

function M.telescope_commands()
  require("telescope").extensions.metals.commands()
end

function M.show_logs()
  local config = require("metals.config").get_config_cache()
  if not config or not config.root_dir then
    notify.send("Metals", "Start Metals before opening its logs", vim.log.levels.WARN)
    return
  end

  open_readonly_file(vim.fs.joinpath(config.root_dir, ".metals", "metals.log"), "log")
end

function M.run_doctor()
  require("metals").run_doctor()
end

function M.enable()
  if enabled then
    attach_buf(0)
    notify.replace("scala.metals", "Metals", "Already enabled", vim.log.levels.INFO)
    return
  end
  enabled = true
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "scala", "sbt" },
    group = vim.api.nvim_create_augroup("nvim-metals", { clear = true }),
    callback = function(ev)
      attach_buf(ev.buf)
    end,
  })
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      attach_buf(buf)
    end
  end
  notify.send("Metals", "LSP and DAP enabled", vim.log.levels.INFO)
end

return M
