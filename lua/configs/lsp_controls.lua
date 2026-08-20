-- LSP session actions. <leader>lsp opens a Telescope picker.
-- Disable is this Neovim process only (vim.g.lsp_disabled); Restart turns it back on.

local notify = require "configs.notify"

local M = {}

local function configured_servers()
  local ok, lspconfig = pcall(require, "configs.lspconfig")
  if ok and type(lspconfig.servers) == "table" then
    return lspconfig.servers
  end
  return {}
end

local function client_ids()
  local ids = {}
  for _, client in ipairs(vim.lsp.get_clients()) do
    ids[#ids + 1] = client.id
  end
  return ids
end

local function client_names()
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients()) do
    names[#names + 1] = client.name
  end
  table.sort(names)
  return names
end

local function stop_all_clients()
  local ids = client_ids()
  if #ids > 0 then
    vim.lsp.stop_client(ids, true)
  end
end

-- Stop every running client, then enable configured servers and start for this buffer.
function M.restart()
  vim.g.lsp_disabled = false
  stop_all_clients()
  for _, name in ipairs(configured_servers()) do
    pcall(vim.lsp.enable, name, true)
  end
  vim.defer_fn(function()
    pcall(vim.cmd, "lsp start")
    local names = client_names()
    local msg = #names == 0 and "Restarted (waiting for clients)" or ("Restarted: " .. table.concat(names, ", "))
    notify.send("LSP", msg)
  end, 200)
end

-- Stop clients and prevent auto-start until this Neovim exits (or Restart).
function M.disable_session()
  vim.g.lsp_disabled = true
  for _, name in ipairs(configured_servers()) do
    pcall(vim.lsp.enable, name, false)
  end
  stop_all_clients()
  notify.send("LSP", "Disabled for this session. Restart to enable again.")
end

-- Open the LSP log file in a split.
function M.show_logs()
  local path
  if vim.lsp.log and vim.lsp.log.get_filename then
    path = vim.lsp.log.get_filename()
  else
    path = vim.fn.stdpath "log" .. "/lsp.log"
  end
  vim.cmd("split " .. vim.fn.fnameescape(path))
  vim.bo.filetype = "log"
end

-- :checkhealth vim.lsp (falls back to lspconfig if that file is missing).
function M.show_health()
  if not pcall(vim.cmd, "checkhealth vim.lsp") then
    vim.cmd "checkhealth lspconfig"
  end
end

local actions = {
  {
    id = "restart",
    name = "Restart",
    desc = "Stop all clients, then start again for this buffer",
    run = M.restart,
  },
  {
    id = "disable",
    name = "Disable",
    desc = "Stop LSP and keep it off until this Neovim exits",
    run = M.disable_session,
  },
  {
    id = "logs",
    name = "Show logs",
    desc = "Open the LSP log file",
    run = M.show_logs,
  },
  {
    id = "health",
    name = "Show health",
    desc = "Run :checkhealth vim.lsp",
    run = M.show_health,
  },
}

function M.picker()
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local telescope_actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local previewers = require "telescope.previewers"
  local entry_display = require "telescope.pickers.entry_display"

  local displayer = entry_display.create {
    separator = "  ",
    items = {
      { width = 14 },
      { remaining = true },
    },
  }

  pickers
    .new({
      initial_mode = "normal",
    }, {
      prompt_title = "LSP",
      finder = finders.new_table {
        results = actions,
        entry_maker = function(item)
          return {
            value = item,
            ordinal = item.name .. " " .. item.desc,
            display = function()
              return displayer {
                { item.name, "TelescopeResultsIdentifier" },
                { item.desc, "TelescopeResultsComment" },
              }
            end,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = previewers.new_buffer_previewer {
        title = "LSP",
        define_preview = function(self, entry)
          local item = entry.value
          local names = client_names()
          local lines = {
            item.name,
            "",
            item.desc,
            "",
            "Disabled this session: " .. (vim.g.lsp_disabled and "yes" or "no"),
            "Active clients: " .. (#names == 0 and "(none)" or table.concat(names, ", ")),
          }
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        end,
      },
      mappings = require "mappings.telescope.defaults",
      attach_mappings = function(prompt_bufnr, _)
        telescope_actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          telescope_actions.close(prompt_bufnr)
          if selection and selection.value then
            selection.value.run()
          end
        end)
        return true
      end,
    })
    :find()
end

function M.setup()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp_controls_session", { clear = true }),
    callback = function(ev)
      if not vim.g.lsp_disabled then
        return
      end
      local id = ev.data and ev.data.client_id
      if not id then
        return
      end
      pcall(vim.lsp.buf_detach_client, ev.buf, id)
      pcall(vim.lsp.stop_client, id, true)
    end,
  })
end

M.setup()

return M
