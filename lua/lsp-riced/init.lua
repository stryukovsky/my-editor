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

-- Reattach shared clients; restart an unshared process after it has exited.
local disabled_configs = {}

function M.restart(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local configs = disabled_configs[bufnr] or {}
  for _, client in ipairs(buffer_clients(bufnr)) do
    configs[#configs + 1] = { config = client.config, client = client }
  end
  vim.b[bufnr].lsp_disabled = false
  disabled_configs[bufnr] = nil
  stop_buffer_clients(bufnr)
  for _, saved in ipairs(configs) do
    local attempts = 0
    local function start()
      if not vim.api.nvim_buf_is_valid(bufnr) or vim.b[bufnr].lsp_disabled then
        return
      end
      if
        saved.client
        and not attached_elsewhere(saved.client, bufnr)
        and not saved.client:is_stopped()
      then
        attempts = attempts + 1
        if attempts < 100 then
          vim.defer_fn(start, 50)
        else
          notify.send(
            "LSP",
            "Timed out stopping " .. saved.config.name,
            vim.log.levels.WARN
          )
        end
        return
      end
      vim.api.nvim_buf_call(bufnr, function()
        local id = vim.lsp.start(saved.config, { bufnr = bufnr })
        if id then
          notify.send("LSP", "Attached " .. saved.config.name)
        end
      end)
    end
    start()
  end
  if #configs == 0 then
    notify.send("LSP", "No clients to restart", vim.log.levels.INFO)
  end
end

-- Detach this buffer's clients and block auto-start on it until Restart.
---@param bufnr integer
function M.disable_session(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.b[bufnr].lsp_disabled = true
  local clients = buffer_clients(bufnr)
  if #clients > 0 then
    disabled_configs[bufnr] = {}
    for _, client in ipairs(clients) do
      table.insert(
        disabled_configs[bufnr],
        { config = client.config, client = client }
      )
    end
  end
  local names = stop_buffer_clients(bufnr)
  local msg = #names == 0 and "No clients on this buffer"
    or ("Disabled: " .. names_label(names))
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
  local source_win = vim.api.nvim_get_current_win()
  if not pcall(function()
    vim.cmd "checkhealth vim.lsp"
  end) then
    vim.cmd "checkhealth lspconfig"
  end
  local report_win = vim.api.nvim_get_current_win()
  local report_buf = vim.api.nvim_get_current_buf()
  vim.bo[report_buf].buflisted = true
  vim.bo[report_buf].buftype = "nofile"
  vim.bo[report_buf].bufhidden = "hide"
  vim.bo[report_buf].swapfile = false
  vim.bo[report_buf].modified = false
  vim.bo[report_buf].readonly = true
  vim.bo[report_buf].modifiable = false
  if report_win ~= source_win and vim.api.nvim_win_is_valid(source_win) then
    vim.api.nvim_win_set_buf(source_win, report_buf)
    vim.api.nvim_set_current_win(source_win)
    vim.api.nvim_win_close(report_win, true)
  end
end

---@param bufnr integer
function M.actions_for(bufnr)
  local connected = client_names_for(bufnr)
  local names = names_label(connected)
  local items = {
    {
      id = "restart",
      name = "Restart",
      desc = names,
      preview_desc = "Restart unshared clients; reattach shared clients without interrupting other buffers",
      run = function()
        M.restart(bufnr)
      end,
    },
    {
      id = "disable",
      name = "Disable",
      desc = names,
      preview_desc = "Detach this buffer and keep LSP off here until Restart",
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
  local process = require "lsp-riced.process"
  if #process.running() > 0 then
    items[#items + 1] = {
      id = "kill",
      name = "Force kill LSP",
      desc = "Running LSP processes",
      preview_desc = "Pick any tracked LSP process in this Neovim instance and send SIGKILL by PID",
      run = function()
        vim.schedule(process.picker)
      end,
    }
  end
  local start_items = require("lsp-riced.start").actions(bufnr, #connected == 0)
  if #connected == 0 then
    items = vim.tbl_filter(function(item)
      return item.id ~= "restart" and item.id ~= "disable"
    end, items)
    for i = #start_items, 1, -1 do
      table.insert(items, 1, start_items[i])
    end
  else
    vim.list_extend(items, start_items)
  end
  vim.list_extend(
    items,
    require("lsp-riced.servers").actions(bufnr, buffer_clients(bufnr))
  )
  return items
end

function M.picker(bufnr)
  require("lsp-riced.picker").show(bufnr or vim.api.nvim_get_current_buf())
end

function M.setup()
  require("lsp-riced.process").setup()
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = vim.api.nvim_create_augroup("lsp_riced_cleanup", { clear = true }),
    callback = function(ev)
      disabled_configs[ev.buf] = nil
    end,
  })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp_riced_session", { clear = true }),
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

return M
