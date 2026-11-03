local source = {}
function source.new()
  return setmetatable({}, { __index = source })
end
function source:enabled()
  return vim.b.terminal_command == true
end
function source:get_trigger_characters()
  return { "/", ".", " " }
end

-- Decode just the current shell word. Never evaluate shell input.
function source.word(before)
  local start, value, quote, escaped = 0, "", nil, false
  for i = 1, #before do
    local char = before:sub(i, i)
    if escaped then
      value = value .. char
      escaped = false
    elseif char == "\\" and quote ~= "'" then
      escaped = true
    elseif quote then
      if char == quote then
        quote = nil
      else
        value = value .. char
      end
    elseif char == "'" or char == '"' then
      quote = char
    elseif char:match "[%s|;&<>()]" then
      start, value = i, ""
    else
      value = value .. char
    end
  end
  return start, value, quote
end

function source:get_completions(ctx, callback)
  local start, token, quote = source.word(ctx.line:sub(1, ctx.cursor[2]))
  local end_col = ctx.cursor[2]
  if quote and ctx.line:sub(end_col + 1, end_col + 1) == quote then
    end_col = end_col + 1
  end
  local function respond(items)
    callback {
      items = items,
      is_incomplete_forward = true,
      is_incomplete_backward = true,
    }
  end
  if token:sub(1, 1) == "-" then
    return respond {}
  end
  local prefix = token:match "^(.*[/])" or ""
  local basename = token:sub(#prefix + 1)
  local cwd = vim.b[ctx.bufnr].terminal_command_cwd or vim.fn.getcwd()
  local expanded = prefix
  if expanded:sub(1, 2) == "~/" then
    expanded = vim.env.HOME .. expanded:sub(2)
  end
  expanded = expanded:gsub("^%${([%w_]+)}", function(key)
    return vim.env[key] or "${" .. key .. "}"
  end)
  expanded = expanded:gsub("^%$([%w_]+)", function(key)
    return vim.env[key] or "$" .. key
  end)
  local directory = expanded:sub(1, 1) == "/" and expanded
    or vim.fs.joinpath(cwd, expanded)
  -- Completion after an expansion inserts the absolute path so quoting stays correct.
  local insert_prefix = expanded ~= prefix and expanded or prefix
  local scan = vim.uv.fs_scandir(directory)
  do
    local items = {}
    if scan then
      while #items < 2000 do
        local name, kind = vim.uv.fs_scandir_next(scan)
        if not name then
          break
        end
        if name:sub(1, 1) ~= "." or basename:sub(1, 1) == "." then
          if kind == "link" then
            local stat = vim.uv.fs_stat(directory .. "/" .. name)
            kind = stat and stat.type or kind
          end
          local suffix = kind == "directory" and "/" or ""
          local path = insert_prefix .. name .. suffix
          -- Quoting the whole word also handles partially typed quoted paths.
          items[#items + 1] = {
            label = name .. suffix,
            path = path,
            directory = kind == "directory",
          }
        end
      end
    end
    do
      for _, item in ipairs(items) do
        item.kind = item.directory
            and vim.lsp.protocol.CompletionItemKind.Folder
          or vim.lsp.protocol.CompletionItemKind.File
        item.textEdit = {
          newText = vim.fn.shellescape(item.path),
          range = {
            start = { line = ctx.cursor[1] - 1, character = start },
            ["end"] = { line = ctx.cursor[1] - 1, character = end_col },
          },
        }
        item.path, item.directory = nil, nil
      end
      respond(items)
    end
  end
end
return source
