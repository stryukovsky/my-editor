local M = {}
local icons =
  { restart = "󰑐", disable = "󰅛", logs = "󰋚", health = "󰓙" }
local function client_names_for(bufnr)
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    names[#names + 1] = client.name
  end
  table.sort(names)
  return names
end
local function names_label(names)
  return #names > 0 and table.concat(names, ", ") or "(none)"
end

---@param bufnr? integer
function M.show(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  require "utils.ui_prevent_mess"()
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local telescope_actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local previewers = require "telescope.previewers"
  local entry_display = require "telescope.pickers.entry_display"

  local displayer = entry_display.create {
    separator = "  ",
    items = {
      { width = 2 },
      { width = 25 },
      { remaining = true },
    },
  }

  pickers
    .new({
      initial_mode = "normal",
      sorting_strategy = "ascending",
      layout_strategy = "horizontal",
      layout_config = {
        width = 0.85,
        height = 0.65,
        preview_width = 0.45,
        prompt_position = "top",
      },
    }, {
      prompt_title = "󰒋  LSP · " .. names_label(client_names_for(bufnr)),
      finder = finders.new_table {
        results = require("lsp-riced").actions_for(bufnr),
        entry_maker = function(item)
          return {
            value = item,
            ordinal = item.name .. " " .. item.desc,
            display = function()
              return displayer {
                { icons[item.id] or "󰒓", "TelescopeResultsSpecialComment" },
                { item.name, "TelescopeResultsIdentifier" },
                { item.desc, "TelescopeResultsComment" },
              }
            end,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = previewers.new_buffer_previewer {
        title = "Action details",
        define_preview = function(self, entry)
          local item = entry.value
          local names = client_names_for(bufnr)
          local lines = {
            item.name,
            "",
            item.preview_desc or item.desc,
            "",
            "Disabled this buffer: "
              .. (vim.b[bufnr].lsp_disabled and "yes" or "no"),
            "Clients on this buffer: " .. names_label(names),
          }
          lines[#lines + 1] = ""
          for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
            lines[#lines + 1] =
              string.format("%s · #%d", client.name, client.id)
            lines[#lines + 1] = "Root: "
              .. (client.config.root_dir or "single file")
          end
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          vim.wo[self.state.winid].wrap = true
        end,
      },
      mappings = require "mappings.telescope.defaults",
      attach_mappings = function(prompt_bufnr, _)
        telescope_actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          telescope_actions.close(prompt_bufnr)
          if
            selection
            and selection.value
            and vim.api.nvim_buf_is_valid(bufnr)
          then
            vim.api.nvim_buf_call(bufnr, function()
              local ok, err = pcall(selection.value.run)
              if not ok then
                require("configs.notify").send(
                  "LSP",
                  tostring(err),
                  vim.log.levels.ERROR
                )
              end
            end)
          end
        end)
        return true
      end,
    })
    :find()
end

return M
