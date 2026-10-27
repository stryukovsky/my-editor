local map = require "mappings.map"

local icons = {
  npm = "",
  pnpm = "",
  yarn = "",
  bun = "",
  node = "",
  deno = "",
  python = "",
  python3 = "",
  pytest = "",
  uv = "",
  poetry = "",
  pip = "",
  cargo = "",
  rustc = "",
  go = "",
  make = "",
  cmake = "",
  docker = "",
  java = "",
  javac = "",
  mvn = "",
  gradle = "",
}

local function job_icon(task)
  -- Prefer the command, but also recognize tools in shell commands and task names.
  local command = type(task.cmd) == "table" and table.concat(task.cmd, " ")
    or task.cmd
    or ""
  for word in (command .. " " .. task.name):lower():gmatch "[%w_+.-]+" do
    if icons[word] then
      return icons[word]
    end
  end
  return ""
end

return {
  desc = "Show task logs in a pinned, named buffer",
  constructor = function()
    local close_autocmd
    local function clear_close_autocmd()
      if close_autocmd then
        pcall(vim.api.nvim_del_autocmd, close_autocmd)
        close_autocmd = nil
      end
    end
    return {
      on_start = function(_, task)
        clear_close_autocmd()
        local win = vim.api.nvim_get_current_win()
        -- Overseer unlists the output after on_start; restore it afterward.
        vim.schedule(function()
          local buf = task:get_bufnr()
          if
            task:is_disposed()
            or not buf
            or not vim.api.nvim_buf_is_valid(buf)
          then
            return
          end
          vim.bo[buf].buflisted = true
          vim.bo[buf].bufhidden = "hide"
          close_autocmd = vim.api.nvim_create_autocmd(
            { "BufUnload", "BufDelete", "BufWipeout" },
            {
              buffer = buf,
              once = true,
              desc = "Stop Overseer task when its log buffer closes",
              callback = function()
                close_autocmd = nil
                if not task:is_disposed() and task:get_bufnr() == buf then
                  task:stop()
                end
              end,
            }
          )
          map({ "n", "i", "t" }, "<C-c>", function()
            if not task:is_disposed() then
              task:stop()
            end
          end, {
            buffer = buf,
            silent = true,
            desc = "Overseer: terminate task",
          })
          -- The ID avoids collisions between jobs with the same name. Barbar uses
          -- the final path segment as the title, keeping the icon and task name.
          local title = job_icon(task)
            .. " "
            .. task.name:gsub("[/\\]", " ∕ ")
          vim.api.nvim_buf_set_name(
            buf,
            ("overseer://%s/%s"):format(task.id, title)
          )
          if not require("barbar.state").is_pinned(buf) then
            require("barbar.api").toggle_pin(buf)
          end
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_set_buf(win, buf)
            vim.api.nvim_win_call(win, function()
              vim.cmd("lcd " .. vim.fn.fnameescape(task.cwd))
            end)
          end
        end)
      end,
      on_reset = clear_close_autocmd,
      on_dispose = clear_close_autocmd,
    }
  end,
}
