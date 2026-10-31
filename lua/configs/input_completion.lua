local M = {}
local templates

-- Reuse installed and personal VS Code gitcommit snippets, keeping inputs one-line.
local function commit_templates()
  if templates then
    return templates
  end
  templates = {}
  local seen = {}
  for _, path in
    ipairs(vim.api.nvim_get_runtime_file("snippets/gitcommit.json", true))
  do
    local ok, entries = pcall(function()
      return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
    end)
    if ok and type(entries) == "table" then
      local names = vim.tbl_keys(entries)
      table.sort(names)
      for _, name in ipairs(names) do
        local entry = entries[name]
        local body = type(entry.body) == "table" and entry.body[1] or entry.body
        local prefixes = type(entry.prefix) == "table" and entry.prefix
          or { entry.prefix }
        for _, prefix in ipairs(prefixes) do
          if
            type(prefix) == "string"
            and type(body) == "string"
            and not seen[prefix]
          then
            seen[prefix] = true
            templates[#templates + 1] = {
              word = prefix,
              abbr = prefix,
              menu = name,
              user_data = { input_snippet = body:match "[^\r\n]*" },
            }
          end
        end
      end
    end
  end
  return templates
end

function M.complete(findstart, _)
  local before = vim.api.nvim_get_current_line():sub(1, vim.fn.col "." - 1)
  local token = before:match "[%w_./%-]*$" or ""
  local start = #before - #token
  if findstart == 1 then
    return start
  end
  local items = {}
  if before:sub(1, start):match "^%s*$" then
    vim.list_extend(items, vim.deepcopy(commit_templates()))
  end
  local branch = vim.b.input_git_branch
  if type(branch) == "string" and branch ~= "" then
    items[#items + 1] = { word = branch, menu = "Current branch" }
  end
  if token ~= "" then
    items = vim.fn.matchfuzzy(items, token, { key = "word" })
  end
  return { words = items, refresh = "always" }
end

function M.setup(buf, cwd)
  -- A nonzero native delay exposes a blank popup frame while this float refilters.
  -- Restore the global delay when the input closes or loses focus.
  local previous_delay = vim.o.autocompletedelay
  local delay_restored = false
  vim.o.autocompletedelay = 0
  vim.api.nvim_create_autocmd({ "BufLeave", "BufWipeout" }, {
    buffer = buf,
    callback = function()
      if delay_restored then
        return
      end
      delay_restored = true
      if vim.o.autocompletedelay == 0 then
        vim.o.autocompletedelay = previous_delay
      end
    end,
  })
  vim.bo[buf].completefunc = "v:lua.NativeExtraComplete"
  vim.system(
    { "git", "-C", cwd, "symbolic-ref", "--quiet", "--short", "HEAD" },
    { text = true },
    function(result)
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) and result.code == 0 then
          vim.b[buf].input_git_branch = vim.trim(result.stdout or "")
        end
      end)
    end
  )
  vim.api.nvim_create_autocmd("CompleteDone", {
    buffer = buf,
    callback = function()
      local item = vim.deepcopy(vim.v.completed_item)
      local data = type(item.user_data) == "table" and item.user_data or {}
      if
        type(data.input_snippet) ~= "string" or vim.v.event.reason ~= "accept"
      then
        return
      end
      local cursor = vim.api.nvim_win_get_cursor(0)
      vim.schedule(function()
        if
          not vim.api.nvim_buf_is_valid(buf)
          or vim.api.nvim_get_current_buf() ~= buf
        then
          return
        end
        local row, col = cursor[1] - 1, cursor[2]
        local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
          or ""
        local start = col - #item.word
        if start < 0 or line:sub(start + 1, col) ~= item.word then
          return
        end
        vim.api.nvim_buf_set_text(buf, row, start, row, col, { "" })
        vim.api.nvim_win_set_cursor(0, { row + 1, start })
        vim.snippet.expand(data.input_snippet)
      end)
    end,
  })
end

return M
