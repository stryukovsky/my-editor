local map = require "mappings.map"

local M = { items = {} }

local function highlight_matches(ctx)
  local line = ctx.item.text or ""
  local segments, offset = {}, 0
  for _, range in ipairs(ctx.item.match_ranges or {}) do
    segments[#segments + 1] =
      { text = vim.fn.strtrans(line:sub(offset + 1, range.start)) }
    segments[#segments + 1] = {
      text = vim.fn.strtrans(line:sub(range.start + 1, range["end"])),
      hl = "DiffAdd",
    }
    offset = range["end"]
  end
  segments[#segments + 1] = { text = vim.fn.strtrans(line:sub(offset + 1)) }
  return segments
end

M.config = {
  modes = {
    ripgrep_results = {
      desc = "Ripgrep search results",
      source = "ripgrep_results",
      title = "{hl:Title} Search Results{hl} {hl:Comment}| r to start replacing | f filter these entries{hl}    {count} entries found ",
      format = "{padded_filename} {padded_pos}   {ripgrep_matches}",
      formatters = { ripgrep_matches = highlight_matches },
      auto_preview = false,
      auto_refresh = false,
      keys = { f = false, r = false },
    },
  },
}

function M.get(cb)
  cb(M.items)
end

local function filter(view)
  local results = {}
  for _, item in ipairs(view:flatten()) do
    local location = ("%s:%d:%d"):format(
      vim.fn.fnamemodify(item.filename, ":."),
      item.pos[1],
      item.pos[2] + 1
    )
    results[#results + 1] = {
      value = item,
      filename = item.filename,
      lnum = item.pos[1],
      col = item.pos[2] + 1,
      ordinal = location .. " " .. (item.text or ""),
      display = location .. "  " .. vim.fn.strtrans(item.text or ""),
    }
  end
  if #results == 0 then
    return
  end

  local actions = require "telescope.actions"
  local state = require "telescope.actions.state"
  require("telescope.pickers")
    .new({}, {
      prompt_title = "Filter ripgrep results",
      file_ignore_patterns = {},
      temp__scrolling_limit = math.max(250, #results + 1),
      finder = require("telescope.finders").new_table {
        results = results,
        entry_maker = function(entry)
          return entry
        end,
      },
      sorter = require("telescope.config").values.generic_sorter {},
      previewer = require("telescope.previewers").vim_buffer_vimgrep.new {},
      attach_mappings = function(bufnr, telescope_map)
        local function apply()
          local picker = state.get_current_picker(bufnr)
          local selected = picker:get_multi_selection()
          local keep = {}
          if #selected > 0 then
            for _, entry in ipairs(selected) do
              keep[entry.value] = true
            end
          else
            for entry in picker.manager:iter() do
              keep[entry.value] = true
            end
          end
          if next(keep) then
            local query = state.get_current_line()
            local label = query
            if #selected > 0 or query == "" then
              label = ("%d entries"):format(vim.tbl_count(keep))
            end
            actions.close(bufnr)
            view:filter(function(item)
              return keep[item]
            end, {
              id = "ripgrep_filter",
              template = "{hl:Title}Filter:{hl} {label}",
              data = { label = vim.fn.strtrans(label) },
            })
          end
        end
        telescope_map({ "n", "i" }, "<CR>", false)
        map(
          { "n", "i" },
          "<CR>",
          apply,
          { buffer = bufnr, desc = "Apply result filter" }
        )
        return true
      end,
    })
    :find()
end

-- Live grep returns one row per matching line. Recover every occurrence on
-- those captured lines by rerunning the pattern against the snapshots.
local function find_ranges(items, pattern, callback)
  local lines, line_numbers = {}, {}
  for _, item in ipairs(items) do
    local line = item.text
    if line and not line_numbers[line] then
      lines[#lines + 1] = line
      line_numbers[line] = #lines
    end
  end
  local ok, err = pcall(
    vim.system,
    {
      "rg",
      "--no-config",
      "--json",
      "--smart-case",
      "--crlf",
      "--text",
      "-e",
      pattern,
      "-",
    },
    {
      stdin = table.concat(lines, "\n") .. "\n",
    },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        callback(nil, "Could not recover ripgrep match ranges.")
        return
      end
      local ranges = {}
      for record in
        vim.gsplit(result.stdout, "\n", { plain = true, trimempty = true })
      do
        local event = vim.json.decode(record)
        if event.type == "match" then
          ranges[event.data.line_number] = event.data.submatches
        end
      end

      local by_item = {}
      for _, item in ipairs(items) do
        local offsets = ranges[line_numbers[item.text]]
        if
          not offsets
          or not vim.iter(offsets):any(function(range)
            return range.start == item.pos[2]
          end)
        then
          callback(
            nil,
            ("Could not recover match at %s:%d:%d."):format(
              item.filename,
              item.pos[1],
              item.pos[2] + 1
            )
          )
          return
        end
        by_item[item] = offsets
      end
      callback(by_item)
    end)
  )
  if not ok then
    callback(nil, tostring(err))
  end
end

function M.attach(view, pattern, query)
  local ranges, range_error
  local waiting
  find_ranges(view:flatten(), pattern, function(result, err)
    ranges, range_error = result, err
    if not view:is_open() then
      return
    end
    if ranges then
      for item, offsets in pairs(ranges) do
        item.match_ranges = offsets
        item.cache:clear()
      end
      view:render()
    end
    if waiting then
      waiting()
      waiting = nil
    end
  end)
  local function replace()
    local items = view:flatten()
    if #items == 0 or pattern == "" or view.state.replacement_pending then
      return
    end
    local selected = view:at().item
    view.state.replacement_pending = true
    vim.ui.input(
      { prompt = "Replace ripgrep matches with: ", default = query },
      function(replacement)
        if replacement == nil or not view:is_open() then
          view.state.replacement_pending = false
          return
        end
        local function warn(message)
          require("integrations.notify").send(
            "Ripgrep replacement",
            message,
            vim.log.levels.WARN
          )
        end
        if replacement:find "[\r\n%z]" then
          view.state.replacement_pending = false
          warn "Replacement must be a single line."
          return
        end
        local function open_preview()
          view.state.replacement_pending = false
          if not view:is_open() then
            return
          end
          if not ranges then
            warn(range_error)
            return
          end
          local matches, focused = {}, nil
          for _, item in ipairs(items) do
            for _, range in ipairs(ranges[item]) do
              local match = {
                id = #matches + 1,
                filename = item.filename,
                lnum = item.pos[1],
                start = range.start,
                stop = range["end"],
                line = item.text,
              }
              matches[#matches + 1] = match
              if item == selected and range.start == item.pos[2] then
                focused = match
              end
            end
          end
          require("telescope_pretty_picker.replacer_review").open(
            matches,
            focused or matches[1],
            replacement
          )
        end
        if ranges or range_error then
          open_preview()
        else
          waiting = open_preview
        end
      end
    )
  end
  map("n", "f", function()
    filter(view)
  end, { buffer = view.win.buf, desc = "Filter ripgrep results in Telescope" })
  map(
    "n",
    "r",
    replace,
    { buffer = view.win.buf, desc = "Preview ripgrep replacements" }
  )
end

return M
