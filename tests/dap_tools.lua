-- nvim --headless -u ./init.lua -i NONE '+luafile tests/dap_tools.lua' +qa!
local catalog = require "dap_tools.catalog"
local project = require "dap_tools.project"
local picker = require "dap_tools.picker"
local tools = require "dap_tools"
local dap = require "dap"
local checks = 0
local function check(value, label)
  checks = checks + 1
  assert(value, label)
end
check(not next(dap.configurations), "startup must not register presets")
check(
  not dap.adapters.node
    and not dap.adapters.python
    and not dap.adapters.go
    and not dap.adapters.codelldb,
  "startup must not register adapters"
)
check(vim.fn.maparg("<leader>da", "n") ~= "", "activation keymap missing")
check(
  vim.fn.maparg("<leader>py", "n") == "",
  "Python must use the common activation keymap"
)
local original_cwd = vim.fn.getcwd()
local notify = require "integrations.notify"
local send = notify.send
notify.send = function() end
local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp .. "/.git", "p")
vim.fn.mkdir(tmp .. "/python", "p")
vim.fn.mkdir(tmp .. "/node_modules/ignored", "p")
vim.fn.writefile({}, tmp .. "/foundry.toml")
vim.fn.writefile({}, tmp .. "/package.json")
vim.fn.writefile({}, tmp .. "/python/pyproject.toml")
vim.fn.writefile({}, tmp .. "/node_modules/ignored/go.mod")
local ok, err = xpcall(function()
  local entries = project.rank(tmp, project.files(tmp))
  check(
    entries[1].id == "javascript" and entries[2].id == "python",
    "root and nested manifests must rank first"
  )
  check(
    entries[2].root == tmp .. "/python",
    "nested Python root must be retained"
  )
  local last = ""
  for i, entry in ipairs(entries) do
    if i > 2 then
      check(
        entry.score == 0 and entry.name > last,
        "unmatched languages must be alphabetical"
      )
      last = entry.name
    end
    for _, configs in pairs(catalog.configurations(entry)) do
      for _, config in ipairs(configs) do
        check(
          config.cwd == "${workspaceFolder}",
          "preset cwd missing: " .. config.name
        )
        check(
          config.console == nil,
          "preset must omit console: " .. config.name
        )
      end
    end
    local preview = table.concat(picker.preview(entry), "\n")
    check(
      not preview:find("CONTROLLED BY OTHER PLUGIN", 1, true),
      "obsolete ownership note"
    )
    if entry.id == "rust" then
      check(
        preview:find("codelldb", 1, true)
          and preview:find("Launch executable", 1, true),
        "Rust CodeLLDB presets missing from preview"
      )
    end
  end
  check(
    not next(dap.configurations),
    "preview must not activate configurations"
  )
  local executable = vim.fn.executable
  vim.fn.executable = function(command)
    return command == "codelldb" and 0 or executable(command)
  end
  local activated = tools.activate("rust", { root = tmp })
  vim.fn.executable = executable
  check(
    not activated and not tools.active.rust and not dap.adapters.codelldb,
    "missing executable must not register or activate an adapter"
  )

  vim.cmd.tcd(tmp)
  vim.o.columns, vim.o.lines = 180, 50
  local ui = tools.open()
  check(ui ~= nil, "picker missing")
  check(
    vim.wait(3000, function()
      return ui.manager and ui.manager:num_results() == #entries
    end),
    "picker not populated"
  )
  local ids = {}
  for entry in ui.manager:iter() do
    ids[#ids + 1] = entry.value.id
  end
  check(
    ids[1] == "javascript" and ids[2] == "python",
    "Telescope must preserve project priority"
  )
  require("telescope.actions").select_default(ui.prompt_bufnr)
  check(
    vim.api.nvim_buf_is_valid(ui.prompt_bufnr),
    "mixed-project activation must keep Telescope open"
  )
  check(
    dap.adapters["pwa-node"] and dap.adapters.node,
    "Node adapter aliases missing"
  )
  check(
    #dap.configurations.javascript == 3 and #dap.configurations.typescript == 3,
    "JS/TS presets missing"
  )
  check(
    #dap.configurations.javascriptreact == 3
      and #dap.configurations.typescriptreact == 3,
    "React presets missing"
  )
  require("telescope.actions").close(ui.prompt_bufnr)

  dap.configurations.javascript[#dap.configurations.javascript + 1] = {
    name = "Custom",
    type = "node",
    request = "launch",
    cwd = "${workspaceFolder}",
  }
  vim.fn.delete(tmp .. "/python/pyproject.toml")
  ui = tools.open()
  check(
    vim.wait(3000, function()
      return ui.manager and ui.manager:num_results() == #entries
    end),
    "single-match picker not ready"
  )
  require("telescope.actions").select_default(ui.prompt_bufnr)
  check(
    not vim.api.nvim_buf_is_valid(ui.prompt_bufnr),
    "single-match activation must close Telescope"
  )
  check(
    #dap.configurations.javascript == 4
      and dap.configurations.javascript[4].name == "Custom",
    "reactivation must preserve custom configurations without duplicating presets"
  )
  check(tools.activate("go", { root = tmp }), "Go activation failed")
  check(
    dap.adapters.go and #dap.configurations.go == 4,
    "Go adapter and presets missing"
  )
  check(tools.activate("cpp", { root = tmp }), "C/C++ activation failed")
  check(
    dap.adapters.codelldb
      and #dap.configurations.c == 3
      and #dap.configurations.cpp == 3,
    "C/C++ presets missing"
  )

  -- Setup must register the Python transport without starting a debuggee.
  local exepath = vim.fn.exepath
  vim.fn.exepath = function(command)
    return command == "debugpy-adapter" and "/test/debugpy-adapter"
      or exepath(command)
  end
  local activated = tools.activate("python", { root = tmp })
  vim.fn.exepath = exepath
  check(
    activated and dap.adapters.python and dap.adapters.debugpy,
    "Python adapter aliases missing"
  )
  check(#dap.configurations.python == 2, "Python presets missing")

  -- All registration is local to dap_tools; no LSP or source buffer is needed.
  check(
    #vim.lsp.get_clients() == 0,
    "test expects no connected language servers"
  )
  check(
    tools.activate("rust", { root = tmp }),
    "Rust activation must not require rust-analyzer"
  )
  check(
    dap.adapters.codelldb and not dap.adapters.rt_lldb,
    "Rust must use the shared CodeLLDB adapter"
  )
  check(
    #dap.configurations.rust == 3,
    "Rust executable/arguments/attach presets missing"
  )
  for _, config in ipairs(dap.configurations.rust) do
    check(config.type == "codelldb", "Rust preset must use CodeLLDB")
  end
  check(
    tools.activate("scala", { root = tmp }),
    "Scala registration must not require connected Metals"
  )
  check(
    type(dap.adapters.scala) == "function"
      and #dap.configurations.scala == 3
      and #dap.configurations.sbt == 3,
    "Scala transport and presets missing"
  )
  check(
    tools.activate("java", { root = tmp }),
    "Java registration must not require connected jdtls"
  )
  check(
    type(dap.adapters.java) == "function" and #dap.configurations.java == 2,
    "Java transport and presets missing"
  )
  check(
    dap.providers.configs.jdtls == nil,
    "dap_tools must be the source of Java presets"
  )
  check(
    vim.g.rustaceanvim.dap.autoload_configurations == false,
    "Rust must not autoload presets"
  )

  -- Exercise shared envFile handling after removing configs/debuggers.lua.
  vim.fn.writefile({ "FILE_KEY=from_file", "KEEP=file" }, tmp .. "/.env")
  local normalized = dap.listeners.on_config.envFile {
    type = "go",
    envFile = tmp .. "/.env",
    env = { KEEP = "explicit" },
  }
  check(
    normalized.env.FILE_KEY == "from_file"
      and normalized.env.KEEP == "explicit"
      and normalized.envFile == nil,
    "envFile folding or explicit-env precedence changed"
  )
  normalized = dap.listeners.on_config.envFile {
    type = "node",
    envFile = tmp .. "/missing.env",
  }
  check(
    normalized.envFile == nil,
    "missing envFile must be dropped for js-debug"
  )
end, debug.traceback)
notify.send = send
vim.cmd.tcd(original_cwd)
vim.fn.delete(tmp, "rf")
assert(ok, err)
print(
  "PASS "
    .. checks
    .. " DAP activation, project ranking, preview, Telescope, and envFile checks"
)
