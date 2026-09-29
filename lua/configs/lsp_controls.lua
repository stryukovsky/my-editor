-- LSP actions for the buffer that opened the Telescope picker.
-- Disable is that buffer only (vim.b.lsp_disabled); Restart turns it back on.

local notify = require "configs.notify"

local M = {}

---@param bufnr integer
---@return vim.lsp.Client[]
local function buffer_clients(bufnr)
  return vim.lsp.get_clients { bufnr = bufnr }
end

---@param bufnr integer
---@return string[]
local function client_names_for(bufnr)
  local names = {}
  for _, client in ipairs(buffer_clients(bufnr)) do
    names[#names + 1] = client.name
  end
  table.sort(names)
  return names
end

---@param names string[]
---@return string
local function names_label(names)
  if #names == 0 then
    return "(none)"
  end
  return table.concat(names, ", ")
end

---@param client vim.lsp.Client
---@param bufnr integer
---@return boolean
local function attached_elsewhere(client, bufnr)
  for buf in pairs(client.attached_buffers) do
    if buf ~= bufnr then
      return true
    end
  end
  return false
end

-- Detach clients from this buffer; stop a client only if nothing else uses it.
---@param bufnr integer
---@return string[] names
local function stop_buffer_clients(bufnr)
  local names = {}
  for _, client in ipairs(buffer_clients(bufnr)) do
    names[#names + 1] = client.name
    local keep = attached_elsewhere(client, bufnr)
    pcall(vim.lsp.buf_detach_client, bufnr, client.id)
    if not keep then
      pcall(function()
        client:stop(true)
      end)
    end
  end
  table.sort(names)
  return names
end

-- Stop this buffer's clients, then start LSP again for it.
---@param bufnr integer
function M.restart(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.b[bufnr].lsp_disabled = false
  stop_buffer_clients(bufnr)
  vim.defer_fn(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    vim.api.nvim_buf_call(bufnr, function()
      pcall(function()
        vim.cmd "lsp start"
      end)
    end)
    local names = client_names_for(bufnr)
    local msg = #names == 0 and "Restarted (waiting for clients)" or ("Restarted: " .. names_label(names))
    notify.send("LSP", msg)
  end, 200)
end

-- Detach this buffer's clients and block auto-start on it until Restart.
---@param bufnr integer
function M.disable_session(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.b[bufnr].lsp_disabled = true
  local names = stop_buffer_clients(bufnr)
  local msg = #names == 0 and "No clients on this buffer" or ("Disabled: " .. names_label(names))
  notify.send("LSP", msg)
end

-- Open the LSP log file as a normal listed buffer.
function M.show_logs()
  local path
  if vim.lsp.log and vim.lsp.log.get_filename then
    path = vim.lsp.log.get_filename()
  else
    path = vim.fn.stdpath "log" .. "/lsp.log"
  end
  vim.cmd("edit " .. vim.fn.fnameescape(path))
  vim.bo.filetype = "log"
end

-- :checkhealth vim.lsp (falls back to lspconfig if that file is missing).
function M.show_health()
  if
    not pcall(function()
      vim.cmd "checkhealth vim.lsp"
    end)
  then
    vim.cmd "checkhealth lspconfig"
  end
end

---@param bufnr integer
local function actions_for(bufnr)
  local names = names_label(client_names_for(bufnr))
  return {
    {
      id = "restart",
      name = "Restart",
      desc = names,
      preview_desc = "Stop these clients on this buffer, then start again",
      run = function()
        M.restart(bufnr)
      end,
    },
    {
      id = "disable",
      name = "Disable",
      desc = names,
      preview_desc = "Stop these clients on this buffer and keep them off until Restart",
      run = function()
        M.disable_session(bufnr)
      end,
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
end

---@param bufnr? integer
function M.picker(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  require("utils.ui_prevent_mess")()
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
        results = actions_for(bufnr),
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
          local names = client_names_for(bufnr)
          local lines = {
            item.name,
            "",
            item.preview_desc or item.desc,
            "",
            "Disabled this buffer: " .. (vim.b[bufnr].lsp_disabled and "yes" or "no"),
            "Clients on this buffer: " .. names_label(names),
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
      if not vim.b[ev.buf].lsp_disabled then
        return
      end
      local id = ev.data and ev.data.client_id
      if not id then
        return
      end
      pcall(vim.lsp.buf_detach_client, ev.buf, id)
    end,
  })
end

M.setup()

return M
