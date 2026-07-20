local map = require "mappings.map"
local templates = require "configs.templates"

map("n", "<leader>te", function()
  local items = templates.list()
  if #items == 0 then
    vim.notify("No templates available", vim.log.levels.WARN)
    return
  end

  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values

  pickers.new({}, {
    prompt_title = "Templates",
    finder = finders.new_table {
      results = items,
      entry_maker = function(item)
        return {
          value = item.name,
          display = item.name,
          ordinal = item.name,
          destination = item.destination,
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(_, map)
      map("i", "<CR>", function(prompt_bufnr)
        local selection = require("telescope.actions.state").get_selected_entry()
        if selection then
          require("telescope.actions").close(prompt_bufnr)
          templates.create(selection.value)
        end
      end)
      map("n", "<CR>", function(prompt_bufnr)
        local selection = require("telescope.actions.state").get_selected_entry()
        if selection then
          require("telescope.actions").close(prompt_bufnr)
          templates.create(selection.value)
        end
      end)
      return true
    end,
  }):find()
end, { desc = "telescope templates" })