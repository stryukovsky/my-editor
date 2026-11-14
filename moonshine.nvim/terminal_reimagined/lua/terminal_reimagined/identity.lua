local M = {}

local taken_names = {}
local icons = {
  "󰄛",
  "",
  "󰢛",
  "",
  "",
  "",
  "󰢚",
  "󰝱",
  "",
  "☀",
  "☾",
  "♫",
  "⚑",
  "",
  "󰖤",
}

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

local function release_terminal_identity(buf)
  local name = vim.b[buf].terminal_unique_name
  if name then
    taken_names[name] = nil
    vim.b[buf].terminal_unique_name = nil
  end
end

local function set_terminal_name(buf, base)
  release_terminal_identity(buf)
  local name = unique_name(base)
  vim.api.nvim_buf_set_name(buf, name)
  vim.b[buf].terminal_unique_name = name
end

---@param buf integer
---@param base string
function M.set_name(buf, base)
  vim.b[buf].terminal_auto_name = false
  set_terminal_name(buf, base)
end

function M.set_auto(buf, label)
  local icon = vim.b[buf].terminal_identity_icon
  if not icon then
    local available = {}
    for _, candidate in ipairs(icons) do
      local used = false
      for _, other in ipairs(vim.api.nvim_list_bufs()) do
        if vim.b[other].terminal_identity_icon == candidate then
          used = true
          break
        end
      end
      if not used then
        available[#available + 1] = candidate
      end
    end
    icon = #available > 0 and available[math.random(#available)]
      or icons[math.random(#icons)]
    vim.b[buf].terminal_identity_icon = icon
  end
  set_terminal_name(buf, label .. "  " .. icon)
  vim.b[buf].terminal_process_label = label
end

function M.setup()
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = vim.api.nvim_create_augroup(
      "TerminalUniqueNames",
      { clear = true }
    ),
    callback = function(event)
      release_terminal_identity(event.buf)
    end,
  })
end

return M
