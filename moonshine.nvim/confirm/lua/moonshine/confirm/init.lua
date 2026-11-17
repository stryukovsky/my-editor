local M = {}
local original
local active = false

local function native(message, choices, default, kind)
  return original(
    message,
    choices or "",
    default == nil and 1 or default,
    kind or "Generic"
  )
end

local function choices_from(text, default)
  local choices = {}
  for index, label in
    ipairs(vim.split(text == "" and "&OK" or text, "\n", { plain = true }))
  do
    local marker = label:find("&", 1, true)
    local before, key, after
    if marker and marker < #label then
      before = label:sub(1, marker - 1)
      key = vim.fn.strcharpart(label:sub(marker + 1), 0, 1)
      after = label:sub(marker + 1 + #key)
    else
      key = vim.fn.strcharpart(label, 0, 1)
      before, after = "", label:sub(#key + 1)
    end
    local brackets = index == default and { "[", "]" } or { "(", ")" }
    choices[index] = {
      key = vim.fn.tolower(key),
      label = before .. brackets[1] .. key .. brackets[2] .. after,
    }
  end
  return choices
end

local function wrap(text, width)
  local lines = {}
  for _, line in ipairs(vim.split(text, "\n", { plain = true })) do
    local part = ""
    for index = 0, vim.fn.strchars(line) - 1 do
      local char = vim.fn.strcharpart(line, index, 1)
      if part ~= "" and vim.fn.strdisplaywidth(part .. char) > width then
        lines[#lines + 1], part = part, ""
      end
      part = part .. char
    end
    lines[#lines + 1] = part
  end
  return lines
end

local function confirm(message, choice_text, default, kind)
  if
    type(message) ~= "string"
    or (choice_text ~= nil and type(choice_text) ~= "string")
    or (default ~= nil and (type(default) ~= "number" or default % 1 ~= 0))
    or (kind ~= nil and type(kind) ~= "string")
  then
    return native(message, choice_text, default, kind)
  end

  default = default or 1
  for index, label in
    ipairs(vim.split(choice_text or "", "\n", { plain = true }))
  do
    if vim.fn.tolower(vim.trim((label:gsub("&", "")))) == "yes" then
      default = index
      break
    end
  end
  if active or vim.in_fast_event() or #vim.api.nvim_list_uis() == 0 then
    return native(message, choice_text, default, kind)
  end
  local choices = choices_from(choice_text or "", default)
  local width =
    math.min(vim.o.columns - 4, math.max(72, math.floor(vim.o.columns * 0.6)))
  if width < 12 then
    return native(message, choice_text, default, kind)
  end
  local lines = wrap(message, width - 2)
  lines[#lines + 1] = ""
  local choice_start = #lines
  for _, choice in ipairs(choices) do
    vim.list_extend(lines, wrap(choice.label, width - 2))
  end
  lines[#lines + 1] = ""
  local default_label = "cancel"
  if choices[default] then
    default_label = choices[default].label:gsub("[%[%]()]", "")
  end
  vim.list_extend(
    lines,
    wrap("<CR>: " .. default_label .. " | Esc: cancel", width - 2)
  )
  if #lines > vim.o.lines - vim.o.cmdheight - 4 then
    return native(message, choice_text, default, kind)
  end
  for index, line in ipairs(lines) do
    lines[index] = " " .. line
  end

  local buffer, window
  active = true
  local ok, result = xpcall(function()
    buffer = vim.api.nvim_create_buf(false, true)
    vim.bo[buffer].bufhidden = "wipe"
    vim.bo[buffer].swapfile = false
    vim.b[buffer].completion = false
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
    vim.bo[buffer].modifiable = false
    window = vim.api.nvim_open_win(buffer, false, {
      relative = "editor",
      width = width,
      height = #lines,
      row = math.max(0, math.floor((vim.o.lines - #lines) / 2)),
      col = math.floor((vim.o.columns - width) / 2),
      style = "minimal",
      border = "rounded",
      title = " Confirm ",
      title_pos = "center",
      focusable = false,
      zindex = 60,
    })
    local ns = vim.api.nvim_create_namespace "moonshine.confirm"
    vim.api.nvim_buf_set_extmark(buffer, ns, choice_start, 0, {
      end_row = #lines - 2,
      hl_group = "Question",
      hl_eol = true,
    })
    vim.cmd "redraw"
    while vim.api.nvim_win_is_valid(window) do
      -- Keep the caller synchronous without entering the scratch buffer.
      -- getcharstr reads raw keys; no buffer mappings or mode changes are needed.
      local key = vim.fn.getcharstr()
      if key == "\027" or key == "\003" then
        return 0
      elseif key == "\r" or key == "\n" then
        return default >= 1 and default <= #choices and default or 0
      end
      key = vim.fn.tolower(key)
      for index, choice in ipairs(choices) do
        if key == choice.key then
          return index
        end
      end
    end
    return 0
  end, function(err)
    return tostring(err)
  end)
  if window and vim.api.nvim_win_is_valid(window) then
    pcall(vim.api.nvim_win_close, window, true)
  end
  if buffer and vim.api.nvim_buf_is_valid(buffer) then
    pcall(vim.api.nvim_buf_delete, buffer, { force = true })
  end
  active = false
  vim.cmd "redraw"
  if not ok then
    if result:lower():find "interrupt" then
      return 0
    end
    error(result, 0)
  end
  return result
end

function M.setup()
  if not original then
    original = vim.fn.confirm
  end
  vim.fn.confirm = confirm
end

function M.teardown()
  if original and vim.fn.confirm == confirm then
    vim.fn.confirm = original
  end
end

return M
