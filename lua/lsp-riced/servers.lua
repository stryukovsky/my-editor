-- Only attached servers contribute actions. Scala can be enabled before attachment.
local M = {}

function M.actions(bufnr, clients)
  local items = {}
  local function add(server, name, desc, run)
    items[#items + 1] =
      { name = name, desc = server, preview_desc = desc, run = run }
  end
  local function command(client, cmd, args)
    if client:is_stopped() or not vim.lsp.buf_is_attached(bufnr, client.id) then
      vim.notify("LSP client is no longer attached", vim.log.levels.WARN)
      return
    end
    client:request(
      "workspace/executeCommand",
      { command = cmd, arguments = args },
      function(err)
        if err then
          vim.notify(err.message, vim.log.levels.ERROR)
        end
      end,
      bufnr
    )
  end
  local has_metals = false
  for _, client in ipairs(clients) do
    if client.name == "metals" then
      has_metals = true
      for _, action in ipairs {
        { "Metals Doctor", "Inspect build and workspace health", "run_doctor" },
        { "Metals logs", "Open this workspace's Metals log", "show_logs" },
        {
          "Metals commands",
          "Browse the Metals command palette",
          "telescope_commands",
        },
      } do
        add("metals", action[1], action[2], function()
          require("configs.scalametals")[action[3]]()
        end)
      end
    elseif client.name == "rust_analyzer" or client.name == "rust-analyzer" then
      if vim.fn.exists ":RustLsp" == 2 then
        for _, action in ipairs {
          { "Reload workspace", "reloadWorkspace", "Reload Cargo workspace" },
          {
            "Rebuild proc macros",
            "rebuildProcMacros",
            "Rebuild procedural macros",
          },
          {
            "Expand macro",
            "expandMacro",
            "Expand the macro under the cursor",
          },
          {
            "Explain error",
            "explainError",
            "Explain the compiler diagnostic under the cursor",
          },
          {
            "Open Cargo.toml",
            "openCargo",
            "Open this crate's Cargo manifest",
          },
        } do
          add(client.name, action[1], action[3], function()
            vim.cmd.RustLsp { action[2] }
          end)
        end
      end
    elseif client.name == "pyright" or client.name == "basedpyright" then
      add(
        client.name,
        "Organize imports",
        "Organize Python imports in this file",
        function()
          command(
            client,
            client.name .. ".organizeimports",
            { vim.uri_from_bufnr(bufnr) }
          )
        end
      )
      add(
        client.name,
        "Python interpreter",
        "Set the interpreter for this LSP workspace (does not install packages)",
        function()
          vim.ui.input({
            prompt = "Python executable: ",
            completion = "file",
            default = ((client.settings or {}).python or {}).pythonPath,
          }, function(path)
            if not path or vim.trim(path) == "" or client:is_stopped() then
              return
            end
            path = vim.fn.expand(path)
            if vim.fn.executable(path) ~= 1 then
              vim.notify("Not executable: " .. path, vim.log.levels.WARN)
              return
            end
            client.settings = vim.tbl_deep_extend(
              "force",
              client.settings or {},
              { python = { pythonPath = path } }
            )
            client:notify(
              "workspace/didChangeConfiguration",
              { settings = client.settings }
            )
          end)
        end
      )
    elseif client.name == "gopls" then
      add(
        client.name,
        "Organize imports",
        "Apply Go source.organizeImports to this file",
        function()
          vim.lsp.buf.code_action {
            context = { only = { "source.organizeImports" }, diagnostics = {} },
            filter = function(action, id)
              return id == client.id
            end,
            apply = true,
          }
        end
      )
    end

    -- The server supplies command names; arguments are explicit rather than guessed.
    local commands = (client.server_capabilities.executeCommandProvider or {}).commands
      or {}
    if #commands > 0 and client.name ~= "metals" then
      add(
        client.name,
        "Server commands",
        "Advanced: choose an advertised command and supply its JSON argument array",
        function()
          local sorted = vim.deepcopy(commands)
          table.sort(sorted)
          vim.ui.select(
            sorted,
            { prompt = client.name .. " commands" },
            function(cmd)
              if not cmd then
                return
              end
              vim.ui.input(
                { prompt = cmd .. " — JSON arguments: ", default = "[]" },
                function(input)
                  if not input then
                    return
                  end
                  local ok, args = pcall(
                    vim.json.decode,
                    input,
                    { luanil = { object = true, array = true } }
                  )
                  if
                    not ok
                    or not input:match "^%s*%["
                    or type(args) ~= "table"
                    or not vim.islist(args)
                  then
                    vim.notify(
                      "Expected a JSON array of command arguments",
                      vim.log.levels.WARN
                    )
                    return
                  end
                  command(client, cmd, args)
                end
              )
            end
          )
        end
      )
    end
  end
  if
    not has_metals
    and (vim.bo[bufnr].filetype == "scala" or vim.bo[bufnr].filetype == "sbt")
  then
    add(
      "scala",
      "Enable Metals",
      "Enable Metals LSP and DAP for Scala buffers",
      function()
        require("configs.scalametals").enable()
      end
    )
  end
  return items
end

return M
