local M = {}
local calendar = require "moonshine.gospel.calendar"
local root = vim.fn.stdpath "config" .. "/moonshine.nvim/gospel/readings/"
local books =
  { ["Мф"] = "Mt", ["Мк"] = "Mk", ["Лк"] = "Lk", ["Ин"] = "Jn" }
local lectionary
local gospels = {}

local function chapters(book)
  if not gospels[book] then
    local result, chapter = {}, nil
    for _, line in ipairs(vim.fn.readfile(root .. books[book] .. ".text")) do
      local number = line:match "^#(%d+)$"
      if number then
        chapter = {}
        result[tonumber(number)] = chapter
      else
        local verse, text = line:match "^(%d+)|(.+)$"
        if verse then
          chapter[tonumber(verse)] = text
        end
      end
    end
    gospels[book] = result
  end
  return gospels[book]
end

local function verse_position(position, chapter)
  local explicit_chapter, verse = position:match "^(%d+):(%d+)$"
  return tonumber(explicit_chapter) or chapter, tonumber(verse or position)
end

local function passage(reference)
  local result = {}
  for book, ranges in reference:gmatch "([^%s.;]+)%.([%d:,-]+)" do
    local gospel = chapters(book)
    local chapter
    for range in ranges:gmatch "[^,]+" do
      local first, last = range:match "^([^-]+)%-?(.*)$"
      local start_chapter, start_verse = verse_position(first, chapter)
      local end_chapter, end_verse =
        verse_position(last ~= "" and last or first, start_chapter)
      for number = start_chapter, end_chapter do
        local verses = gospel[number]
        local from = number == start_chapter and start_verse or 1
        local to = number == end_chapter and end_verse or #verses
        for verse = from, to do
          result[#result + 1] = assert(verses[verse], reference)
        end
      end
      chapter = end_chapter
    end
  end
  return table.concat(result, " ")
end

local function wrap(lines, text, width)
  local line = ""
  for word in text:gmatch "%S+" do
    local next_line = line == "" and word or line .. " " .. word
    if line ~= "" and vim.api.nvim_strwidth(next_line) > width then
      lines[#lines + 1] = line
      line = word
    else
      line = next_line
    end
  end
  lines[#lines + 1] = line
end

function M.footer(date)
  lectionary = lectionary
    or vim.json.decode(
      table.concat(vim.fn.readfile(root .. "lectionary.json"), "\n")
    )
  date = date or os.date "*t"
  local references = calendar.readings(lectionary, date)
  local lines = { "" }
  local width = math.max(1, math.min(76, vim.api.nvim_win_get_width(0) - 6))
  wrap(lines, calendar.week_label(date), width)
  lines[#lines + 1] = "Евангелие дня"
  if #references == 0 then
    wrap(
      lines,
      "Сегодня нет евангельского чтения на литургии.",
      width
    )
  end
  for _, reference in ipairs(references) do
    lines[#lines + 1] = ""
    wrap(lines, (reference:gsub("-", "–")), width)
    wrap(lines, passage(reference), width)
  end
  return lines
end

return M
