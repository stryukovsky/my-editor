local M = {}

-- Use :lsp completion when available; older Neovim versions expose configs on runtimepath.
function M.names()
  local ok, completed = pcall(vim.fn.getcompletion, "lsp enable ", "cmdline")
  local names = {}
  for _, name in ipairs(ok and completed or {}) do
    names[name] = true
  end
  for _, path in ipairs(vim.api.nvim_get_runtime_file("lsp/*.lua", true)) do
    names[vim.fn.fnamemodify(path, ":t:r")] = true
  end
  for name in pairs(vim.lsp.config._configs or {}) do
    if name ~= "*" then
      names[name] = true
    end
  end
  local result = vim.tbl_keys(names)
  table.sort(result)
  return result
end

function M.enable(bufnr, name)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  vim.b[bufnr].lsp_disabled = false
  vim.api.nvim_buf_call(bufnr, function()
    local ok, err = pcall(vim.lsp.enable, name)
    if not ok then
      vim.notify(tostring(err), vim.log.levels.ERROR)
    end
  end)
end

function M.actions(bufnr, empty)
  local items = {}
  if empty then
    local ft = vim.bo[bufnr].filetype
    for _, name in ipairs(M.names()) do
      local ok, config = pcall(function()
        return vim.lsp.config[name]
      end)
      if
        ok
        and config
        and config.filetypes
        and vim.tbl_contains(config.filetypes, ft)
      then
        items[#items + 1] = {
          id = "start",
          name = "Start " .. name,
          desc = ft,
          preview_desc = "Enable "
            .. name
            .. " using its configured command and workspace detection",
          run = function()
            M.enable(bufnr, name)
          end,
        }
      end
    end
  end
  items[#items + 1] = {
    id = "start",
    name = "Enable another LSP",
    desc = "Browse LSP configurations",
    preview_desc = "Pick an LSP from :lsp enable completion and runtime configurations. Filetype and workspace rules still apply.",
    run = function()
      -- Open after the outer action's nvim_buf_call restores its window.
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
          M.picker(bufnr)
        end
      end)
    end,
  }
  return items
end

function M.picker(bufnr)
  local actions = require "telescope.actions"
  local state = require "telescope.actions.state"
  require("telescope.pickers")
    .new({ initial_mode = "insert" }, {
      prompt_title = "Enable LSP",
      finder = require("telescope.finders").new_table { results = M.names() },
      sorter = require("telescope.config").values.generic_sorter {},
      mappings = require "mappings.telescope.defaults",
      attach_mappings = function(prompt)
        actions.select_default:replace(function()
          local entry = state.get_selected_entry()
          actions.close(prompt)
          if entry then
            M.enable(bufnr, entry.value)
          end
        end)
        return true
      end,
    })
    :find()
end

return M
