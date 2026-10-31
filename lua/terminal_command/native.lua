local M = {}
function M.complete(findstart, _)
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col "." - 1
  local files = require "terminal_command.files"
  local start, token = files.word(line:sub(1, col))
  if findstart == 1 then
    return start
  end
  local ctx = {
    bufnr = vim.api.nvim_get_current_buf(),
    line = line,
    cursor = { vim.fn.line ".", col },
  }
  local items = {}
  for _, provider in ipairs { files, require "terminal_command.completion" } do
    provider.new():get_completions(ctx, function(result)
      for _, item in ipairs(result.items) do
        local word = item.textEdit and item.textEdit.newText or item.label
        -- The native menu does not apply LSP text edits; use its word field.
        items[#items + 1] = {
          word = word,
          abbr = item.label,
          menu = item.kind == vim.lsp.protocol.CompletionItemKind.Function
              and "[Command]"
            or "[Path]",
          equal = 1,
          user_data = {
            native_shell_start = start,
            native_shell_word = word,
            native_shell_prefix = line:sub(1, start),
            native_shell_quote = item.textEdit
                and item.textEdit.range["end"].character > col
                and line:sub(col + 1, col + 1)
              or nil,
          },
        }
      end
    end)
  end
  local query = token:match "([^/]*)$" or token
  if query ~= "" then
    items = vim.fn.matchfuzzy(items, query, { key = "abbr" })
  end
  return { words = items, refresh = "always" }
end
return M
