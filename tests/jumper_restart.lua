-- Run twice with JUMPER_RESTART_ROOT=<same temp directory> and
-- JUMPER_RESTART_PHASE=seed, then JUMPER_RESTART_PHASE=check:
-- nvim --headless '+luafile tests/jumper_restart.lua' +qa
local root = assert(vim.env.JUMPER_RESTART_ROOT, "Set JUMPER_RESTART_ROOT")
local phase = assert(vim.env.JUMPER_RESTART_PHASE, "Set JUMPER_RESTART_PHASE")
vim.fn.mkdir(root, "p")
local jumper = require "moonshine.jumper"
jumper.setup { path = root .. "/marks.json" }

local function keys(sequence)
  if sequence:find("<", 1, true) then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(sequence, true, false, true), "x", false)
  else
    vim.cmd.normal { args = { sequence }, bang = false }
  end
end

local function open(name)
  local path = root .. "/" .. name
  vim.cmd.edit { args = { path } }
  return path
end

local function at(name, row)
  assert(vim.api.nvim_buf_get_name(0) == root .. "/" .. name, "Expected " .. name)
  assert(vim.api.nvim_win_get_cursor(0)[1] == row, "Expected " .. name .. ":" .. row)
end

if phase == "seed" then
  for _, entry in ipairs { { "A", "mno" }, { "B", "pqr" }, { "C", "tuv" } } do
    local name, letters = unpack(entry)
    local path = root .. "/" .. name
    vim.fn.writefile({ "one", "two", "three" }, path)
    open(name)
    for i = 1, #letters do
      vim.api.nvim_win_set_cursor(0, { i, 0 })
      keys("m" .. letters:sub(i, i))
    end
  end
  open "A"
  keys "'p"
  at("B", 1)
  print "jumper restart seed passed"
elseif phase == "check" then
  open "A"
  keys "'p"
  at("B", 1)
  keys "[m"
  at("A", 3)
  keys "]]"
  at("B", 1)
  keys ";"
  at("B", 2)
  keys "n"
  at("B", 3)
  keys "[["
  at("B", 2)
  keys "<A-;>"
  at("B", 1)
  keys "N"
  at("A", 3)
  keys "'v"
  at("C", 3)
  keys "]m"
  at("A", 1)
  keys "3]m"
  at("B", 1)
  print "jumper restart check passed"
else
  error("Unknown JUMPER_RESTART_PHASE: " .. phase)
end
