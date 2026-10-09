local map = require "mappings.map"
local notify = require "configs.notify"

local plantuml_ext = {
  puml = true,
  plantuml = true,
  pu = true,
  iuml = true,
}

local mermaid_ext = {
  mmd = true,
  mermaid = true,
}

local function buffer_lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

---PlantUML or mermaid, from the buffer file extension (filetype as fallback).
---@return "plantuml"|"mermaid"|nil
local function diagram_kind()
  local ext = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":e"):lower()
  if mermaid_ext[ext] then
    return "mermaid"
  end
  if plantuml_ext[ext] then
    return "plantuml"
  end
  local ft = vim.bo.filetype
  if ft == "mermaid" then
    return "mermaid"
  end
  if ft == "plantuml" then
    return "plantuml"
  end
end

map("n", "<leader>va", function()
  local kind = diagram_kind()
  local lines = buffer_lines()
  if kind == "mermaid" then
    require("configs.mermaid").visualize(lines)
  elseif kind == "plantuml" then
    require("configs.plantuml").visualize(lines)
  else
    notify.send("Visualize", "Not a PlantUML or Mermaid file", vim.log.levels.WARN)
  end
end, { desc = "Visualize diagram as ASCII" })

map("n", "<leader>vi", function()
  local kind = diagram_kind()
  local lines = buffer_lines()
  if kind == "mermaid" then
    require("configs.mermaid").render_png(lines)
  elseif kind == "plantuml" then
    require("configs.plantuml").render_png(lines)
  else
    notify.send("Visualize", "Not a PlantUML or Mermaid file", vim.log.levels.WARN)
  end
end, { desc = "Visualize diagram as image" })
