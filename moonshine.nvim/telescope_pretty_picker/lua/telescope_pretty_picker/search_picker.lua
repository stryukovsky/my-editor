local M = {}

local function modifiers(prompt)
  local extensions = {}
  local regex = false
  while true do
    local text, modifier = prompt:match "^(.-)%s+([^%s]+)%s*$"
    if not modifier then
      break
    end
    if modifier == "-re" then
      regex = true
    elseif modifier:match "^%.[%w_.+-]+$" then
      table.insert(extensions, modifier)
    else
      break
    end
    prompt = text
  end
  return prompt, extensions, regex
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
  local entry_maker = (opts and opts.entry_maker)
    or require("telescope.config").pickers.live_grep.entry_maker
    or require("telescope.make_entry").gen_from_vimgrep(opts or {})
  opts = vim.tbl_extend("force", opts or {}, {
    prompt_title = (opts and opts.prompt_title or "Global search")
      .. " — .ext to filter files, -re for regex",
    on_input_filter_cb = function(prompt)
      local _, parsed = modifiers(prompt)
      extensions = parsed
      return M.filter(prompt)
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
