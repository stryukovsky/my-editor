local M = {}

function M.parse(prompt)
  local words = vim.split(prompt, "%s+", { trimempty = true })
  local query = { text = "", all = false, extensions = {} }
  if not prompt:match "^%s" then
    query.text = table.remove(words, 1) or ""
  end
  for _, word in ipairs(words) do
    if word == "all" then
      query.all = true
    elseif word:match "^%.[%w_.+-]+$" then
      query.extensions[#query.extensions + 1] = word
    end
  end
  return query
end

function M.accepts(path, extensions)
  if #extensions == 0 then
    return true
  end
  for _, extension in ipairs(extensions) do
    if path:sub(-#extension) == extension then
      return true
    end
  end
  return false
end

function M.open()
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local cwd = vim.fn.getcwd()
  local git = vim.fn.systemlist { "git", "-C", cwd, "rev-parse", "--show-toplevel" }
  local in_git = vim.v.shell_error == 0 and git[1] ~= nil
  if in_git then
    cwd = git[1]
  end
  local opts = { cwd = cwd, hidden = true, wrap_results = true }
  local entry_maker = require("telescope.make_entry").gen_from_file(opts)
  local function source(command)
    return finders.new_oneshot_job(
      command,
      { cwd = cwd, entry_maker = entry_maker, split_char = "\0" }
    )
  end
  local tracked = in_git
      and source { "git", "ls-files", "--cached", "-z", "--", "." }
    or nil
  local all_files
  local function disk_source(all)
    local command = { "rg", "--files", "--hidden", "--null", "--glob", "!.git" }
    if all then
      command[#command + 1] = "--no-ignore"
    end
    return source(command)
  end
  local regular = not in_git and disk_source(false) or nil
  local finder = setmetatable({
    close = function()
      for _, item in pairs {
        tracked = tracked,
        regular = regular,
        all = all_files,
      } do
        item:close()
      end
    end,
  }, {
    __call = function(_, prompt, process_result, process_complete)
      local query = M.parse(prompt)
      local seen = {}
      local function emit(entry)
        if entry and not seen[entry.value] then
          seen[entry.value] = true
          return process_result(entry)
        end
      end
      (tracked or regular)(prompt, emit, function() end)
      if query.all then
        all_files = all_files or disk_source(true)
        all_files(prompt, emit, function() end)
      end
      process_complete()
    end,
  })

  -- Generic fuzzy scoring uses the entire relative path, including directories.
  local base = conf.generic_sorter(opts)
  local picker
  local previous_text = ""
  local preferred = {}
  local query
  local sorter = require("telescope.sorters").Sorter:new {
    discard = false, -- Modifiers can broaden the candidate set without shortening the prompt.
    init = function()
      base:_init()
    end,
    destroy = function()
      base:_destroy()
    end,
    start = function(_, prompt)
      query = M.parse(prompt)
      preferred = {}
      if
        previous_text ~= ""
        and #query.text > #previous_text
        and vim.startswith(query.text, previous_text)
        and picker.manager
      then
        for entry in picker.manager:iter() do
          preferred[entry.value] = true
        end
      end
      previous_text = query.text
      base:_start(query.text)
    end,
    scoring_function = function(_, _, _, entry)
      if not M.accepts(entry.value, query.extensions) then
        return -1
      end
      local score = base:scoring_function(query.text, entry.value, entry)
      if score < 0 then
        return -1
      end
      return (preferred[entry.value] and 0 or 1) + score / (1 + score)
    end,
    highlighter = function(_, prompt, display)
      return base:highlighter(M.parse(prompt).text, display)
    end,
  }
  picker = require("telescope.pickers").new(opts, {
    prompt_title = "`.ext` to filter `all` to search untracked | separate by space",
    results_title = "Files",
    finder = finder,
    sorter = sorter,
    previewer = conf.file_previewer(opts),
    attach_mappings = function(_, map)
      for mode, mappings in pairs(require "mappings.telescope.find_files") do
        for key, action in pairs(mappings) do
          map(mode, key, action)
        end
      end
      return true
    end,
  })
  picker:find()
end

return M
