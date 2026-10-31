local source = {}
function source.new()
  return setmetatable({}, { __index = source })
end
function source:enabled()
  return vim.b.terminal_command == true
end
function source:get_completions(ctx, callback)
  local before = ctx.line:sub(1, ctx.cursor[2])
  local prefix = before:match "([%w_.%-]*)$" or ""
  local head = before:sub(1, #before - #prefix)
  local items = {}
  -- Offer executables only in command position, also after shell separators.
  if head:match "^%s*$" or head:match "[|;&]%s*$" then
    for _, name in ipairs(vim.fn.getcompletion(prefix, "shellcmd")) do
      items[#items + 1] = {
        label = name,
        kind = vim.lsp.protocol.CompletionItemKind.Function,
        textEdit = {
          newText = name,
          range = {
            start = { line = ctx.cursor[1] - 1, character = #before - #prefix },
            ["end"] = { line = ctx.cursor[1] - 1, character = #before },
          },
        },
      }
    end
  end
  callback {
    items = items,
    is_incomplete_forward = true,
    is_incomplete_backward = true,
  }
end
return source
