-- Files picker that also lists directories (Neo-tree `f`).
-- Folders use a directory icon; <cr> on a folder reveals it in Neo-tree.

local finders = require "telescope.finders"
local make_entry = require "telescope.make_entry"
local pickers = require "telescope.pickers"
local conf = require("telescope.config").values
local utils = require "telescope.utils"

local function find_files_and_dirs_command()
  if vim.fn.executable "fd" == 1 then
    return { "fd", "--type", "f", "--type", "d", "--color", "never" }
  end
  if vim.fn.executable "fdfind" == 1 then
    return { "fdfind", "--type", "f", "--type", "d", "--color", "never" }
  end
  return { "find", ".", "(", "-type", "f", "-o", "-type", "d", ")" }
end

local function files_and_dirs_entry_maker(opts)
  local inner = make_entry.gen_from_file(opts)
  return function(line)
    local entry = inner(line)
    if not entry then
      return nil
    end
    local file_display = entry.display
    rawset(entry, "display", function(e)
      if vim.fn.isdirectory(e.path) ~= 1 then
        return file_display(e)
      end
      local display, path_style = utils.transform_path(opts, e.value)
      local icon = ""
      display = icon .. " " .. display
      local style = { { { 0, #icon + 1 }, "NeoTreeDirectoryIcon" } }
      return display, utils.merge_styles(style, path_style, #icon + 1)
    end)
    return entry
  end
end

---@param opts table|nil
local function neotree_fs(opts)
  opts = opts or {}
  opts.hidden = opts.hidden ~= false
  opts.wrap_results = true
  if opts.cwd then
    opts.cwd = utils.path_expand(opts.cwd)
  end

  local find_command = opts.find_command or find_files_and_dirs_command()
  local command = find_command[1]
  if opts.hidden and (command == "fd" or command == "fdfind") then
    find_command[#find_command + 1] = "--hidden"
  end

  opts.entry_maker = opts.entry_maker or files_and_dirs_entry_maker(opts)
  local neotree_state = opts.neotree_state
  opts.neotree_state = nil
  opts.find_command = nil
  local custom_attach = opts.attach_mappings
  opts.attach_mappings = nil

  pickers
    .new(opts, {
      prompt_title = opts.prompt_title or "Find Files",
      __locations_input = true,
      finder = finders.new_oneshot_job(find_command, opts),
      previewer = conf.grep_previewer(opts),
      sorter = conf.file_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        local maps = require("mappings.telescope.neotree_fs")(neotree_state)
        map("n", "<cr>", maps.n["<cr>"])
        map("i", "<cr>", maps.i["<cr>"])
        if custom_attach then
          return custom_attach(prompt_bufnr, map)
        end
        return true
      end,
    })
    :find()
end

return neotree_fs
