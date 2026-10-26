local M = {}
local overseer = require "overseer"

overseer.setup {
  dap = false,
  output = { use_terminal = false },
  component_aliases = {
    default = { "on_exit_set_status", "on_complete_notify", "user.log_buffer" },
  },
}

function M.pick()
  require "utils.ui_prevent_mess"()
  local root = require("configs.projects").current_root() or vim.fn.getcwd()
  local search = { dir = root, filetype = vim.bo.filetype }
  -- The built-in picker skips selection when there is only one template.
  require("overseer.template").list(search, function(templates)
    templates = vim.tbl_filter(function(template)
      return not template.hide
    end, templates)
    if #templates == 0 then
      vim.notify("No project tasks found", vim.log.levels.INFO)
      return
    end
    vim.ui.select(templates, {
      prompt = "Project tasks:",
      kind = "overseer_template",
      format_item = function(template)
        return template.desc and (template.name .. " — " .. template.desc)
          or template.name
      end,
    }, function(template)
      if not template then
        return
      end
      -- Leave the Telescope float before opening the job log.
      vim.schedule(function()
        overseer.run_task(
          { name = template.name, search_params = search },
          function(task, err)
            if not task then
              vim.notify(err or "Cannot create task", vim.log.levels.ERROR)
            end
          end
        )
      end)
    end)
  end)
end

return M
