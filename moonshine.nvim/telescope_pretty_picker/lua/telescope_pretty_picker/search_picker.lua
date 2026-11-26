local M = {}

local function modifiers(prompt)
  local extensions = {}
  local regex = false
  local ignored = false
  while true do
    local text, modifier = prompt:match "^(.-)%s+([^%s]+)%s*$"
    if not modifier then
      break
    end
    if modifier == "-re" then
      regex = true
    elseif modifier == "-i" then
      ignored = true
    elseif modifier:match "^%.[%w_.+-]+$" then
      table.insert(extensions, modifier)
    else
      break
    end
    prompt = text
  end
  return prompt, extensions, regex, ignored
end

function M.filter(prompt)
  local text, _, regex = modifiers(prompt)
  if regex then
    return { prompt = text }
  end
  -- Escape regex syntax so ripgrep treats the request as literal text.
  return { prompt = vim.fn.escape(text, [[\.^$*+?()[]{}|]]) }
end

function M.open(opts)
  local extensions = {}
  local include_ignored = false
  local entry_maker = (opts and opts.entry_maker)
    or require("telescope.config").pickers.live_grep.entry_maker
    or require("telescope.make_entry").gen_from_vimgrep(opts or {})
  local config = require "telescope.config"
  local additional_args = (opts and opts.additional_args)
    or config.pickers.live_grep.additional_args
    or {}
  if type(additional_args) == "function" then
    additional_args = additional_args(opts or {})
  end
  local cwd = (opts and opts.cwd) or vim.uv.cwd()
  local search_dirs = opts and opts.search_dirs
  local function grep_finder(ignored)
    local args = vim.list_extend(
      vim.deepcopy(
        (opts and opts.vimgrep_arguments) or config.values.vimgrep_arguments
      ),
      additional_args
    )
    if ignored then
      args[#args + 1] = "--no-ignore"
    end
    return require("telescope.finders").new_job(function(prompt)
      if not prompt or prompt == "" then
        return nil
      end
      return vim.list_extend(
        vim.list_extend(vim.deepcopy(args), { "--", prompt }),
        search_dirs or {}
      )
    end, function(line)
      return opts.entry_maker(line)
    end, nil, cwd)
  end
  opts = vim.tbl_extend("force", opts or {}, {
    prompt_title = (opts and opts.prompt_title or "Global search")
      .. " — .ext files, -re regex, -i ignored",
    on_input_filter_cb = function(prompt)
      local _, parsed, _, ignored = modifiers(prompt)
      extensions = parsed
      local result = M.filter(prompt)
      if ignored ~= include_ignored then
        include_ignored = ignored
        result.updated_finder = grep_finder(ignored)
      end
      return result
    end,
    entry_maker = function(line)
      local entry = entry_maker(line)
      if entry and #extensions > 0 then
        local filename = entry.filename
        for _, extension in ipairs(extensions) do
          if filename:sub(-#extension) == extension then
            return entry
          end
        end
        return nil
      end
      return entry
    end,
  })
  require("telescope.builtin").live_grep(opts)
end

function M.visual()
  local saved = vim.fn.getreginfo "v"
  vim.cmd [[noautocmd silent normal! "vy]]
  local selection = vim.fn.getreg "v"
  vim.fn.setreg("v", saved)
  M.open { default_text = selection }
end

return M
