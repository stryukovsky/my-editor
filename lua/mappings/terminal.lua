local map = require "mappings.map"
local is_normal_buffer = require "utils.is_normal_buffer"
local is_buffer_terminal = require "utils.is_buffer_terminal"
local is_initial_dashboard = require "utils.is_buffer_initial_dashboard"
local script = require "utils.script"
map("t", "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true })
map("t", "<A-a>", "<C-\\><C-n><C-w>h", { noremap = true, silent = true })
map("t", "<A-s>", "<C-\\><C-n><C-w>j", { noremap = true, silent = true })
map("t", "<A-w>", "<C-\\><C-n><C-w>k", { noremap = true, silent = true })
map("t", "<A-d>", "<C-\\><C-n><C-w>l", { noremap = true, silent = true })

local taken_names = {}

local function unique_name(base)
  if not taken_names[base] then
    taken_names[base] = true
    return base
  end
  local i = 1
  while true do
    local candidate = base .. " (" .. i .. ")"
    if not taken_names[candidate] then
      taken_names[candidate] = true
      return candidate
    end
    i = i + 1
  end
end

local function set_terminal_name(buf, base)
  local name = unique_name(base)
  vim.api.nvim_buf_set_name(buf, name)
  vim.b[buf].terminal_unique_name = name
end

vim.api.nvim_create_autocmd("BufWipeout", {
  group = vim.api.nvim_create_augroup("TerminalUniqueNames", { clear = true }),
  callback = function(event)
    local name = vim.b[event.buf].terminal_unique_name
    if name then
      taken_names[name] = nil
    end
  end,
})

local function random_char()
  math.randomseed(os.time())

  local chars = {
    "",
    "",
    "",
    "󱜿",
    "󱦡",
    "󰟻",
    "󰨶",
    "󱗫",
    "󰉀",
    "󱠂",
    "󱩡",
    "󱀆",
    "󰏖",
    "󱗃",
    "󰢗",
    "󱒕",
    "",
    "󰚆",
    "󰭥",
    "",
    "󰊘",
    "",
    "",
    "󱁏",
    "",
    "",
    "",
    "󰀸",
  }
  return chars[math.random(#chars)]
end

map("n", "<Leader>tn", function()
  if is_buffer_terminal() or is_normal_buffer() or is_initial_dashboard() then
    vim.cmd.terminal()
    vim.cmd.BufferPin()
    local base = "  " .. random_char() .. " "
    set_terminal_name(0, base)
  else
    vim.notify("Cannot start terminal from non-normal buffer", vim.diagnostic.severity.WARN, { timeout = 3000 })
  end
end, { desc = "Terminal: new" })

local function script_interpreter(path)
  local filetype = vim.bo.filetype
  if filetype == "python" or path:match "%.py$" then
    return "python3"
  end
  if filetype == "sh" or filetype == "bash" or path:match "%.sh$" or path:match "%.bash$" then
    return "bash"
  end
end

map("n", "<leader>ex", function()
  if not is_normal_buffer() then
    vim.notify("Open a Bash or Python script first", vim.log.levels.WARN)
    return
  end

  local path = vim.api.nvim_buf_get_name(0)
  local interpreter = script_interpreter(path)
  if path == "" or not interpreter then
    vim.notify("Current file is not a Bash or Python script", vim.log.levels.WARN)
    return
  end
  if vim.bo.modified then
    local written, err = pcall(vim.cmd.write)
    if not written then
      vim.notify("Cannot run unsaved script: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
  end

  local executable_error = script.ensure_user_executable(path)
  if executable_error ~= "" then
    vim.notify("Cannot make script executable: " .. executable_error, vim.log.levels.ERROR)
    return
  end

  local directory = vim.fn.fnamemodify(path, ":h")
  local filename = vim.fn.fnamemodify(path, ":t")
  vim.cmd.terminal()
  vim.cmd.BufferPin()
  set_terminal_name(0, "  Run " .. filename)
  vim.api.nvim_chan_send(vim.b.terminal_job_id, ("cd -- %s && %s -- %s\n"):format(
    vim.fn.shellescape(directory),
    interpreter,
    vim.fn.shellescape("./" .. filename)
  ))

end, { desc = "Terminal: run current Bash or Python script" })

map("n", "<Leader>tr", function()
  local old = vim.b.terminal_unique_name
  if old then
    taken_names[old] = nil
  end
  local base = "  " .. vim.fn.input { prompt = "New buf name: " }
  set_terminal_name(0, base)
end, { desc = "Terminal: rename buffer" })
