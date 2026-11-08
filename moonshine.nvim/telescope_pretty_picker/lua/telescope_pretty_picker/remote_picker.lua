local git = require "moonshine.git"
local notify = require "integrations.notify"
local map = require "mappings.map"
local scheduler = require "moonshine.git.scheduler"
local M = {}

local function tell(message, level)
  notify.send("Git remotes", message, level)
end

-- Read configured URLs, without applying url.*.insteadOf rewrites. Each row
-- owns one URL; push URLs are listed only when explicitly configured.
function M.list(cwd)
  local names, err = git.run({ "remote" }, cwd)
  if not names then
    return nil, err
  end
  local rows = {}
  for name in names:gmatch "[^\n]+" do
    for _, kind in ipairs { "fetch", "push" } do
      local key = "remote." .. name .. (kind == "push" and ".pushurl" or ".url")
      local urls, url_err = git.run(
        { "config", "--null", "--get-all", key },
        cwd,
        { ok_codes = { [0] = true, [1] = true } }
      )
      if not urls then
        return nil, url_err
      end
      for url in urls:gmatch "[^%z]+" do
        rows[#rows + 1] = { name = name, kind = kind, url = url }
      end
    end
  end
  return rows
end

-- HTTP credentials identify a web account, not the SSH transport user.
function M.to_ssh(url, user)
  local authority, path = url:match "^https?://([^/]+)/(.+)$"
  if not authority then
    return nil, "Select an HTTP(S) URL to convert"
  end
  local host = authority:gsub("^.*@", "")
  if not host:match "^[%w._-]+$" or path:find "[?#%s]" then
    return nil,
      "Custom ports or web query/fragment URLs need a manual URL replacement"
  end
  if not user:match "^[%w._-]+$" then
    return nil, "Invalid SSH username"
  end
  return user .. "@" .. host .. ":" .. path
end

-- Git's old-URL argument is an extended regular expression, not a literal.
function M.replace_args(row, url)
  local args = { "remote", "set-url" }
  if row.kind == "push" then
    args[#args + 1] = "--push"
  end
  vim.list_extend(args, {
    "--",
    row.name,
    url,
    "^" .. row.url:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?%{%}%|\\])", "\\%1") .. "$",
  })
  return args
end

function M.open(opts)
  opts = opts or {}
  local state = opts.state
  if not state and vim.bo.filetype == "neo-tree" then
    state = require("neo-tree.sources.manager").get_state_for_window()
  end
  local cwd, err = git.root(opts.cwd or (state and state.path))
  if not cwd then
    tell(err, vim.log.levels.ERROR)
    return
  end
  local rows
  rows, err = M.list(cwd)
  if not rows then
    tell(err, vim.log.levels.ERROR)
    return
  end
  if #rows == 0 then
    tell "No remotes configured"
    return
  end

  local function reopen()
    M.open { cwd = cwd }
  end
  local function change(args, message)
    local fetch = package.loaded["moonshine.git.fetch"]
    local _, change_err = git.run(args, cwd)
    if change_err then
      tell(change_err, vim.log.levels.ERROR)
    else
      tell(message)
      if fetch then
        fetch.refresh_sync_state(cwd, true)
      end
      vim.api.nvim_exec_autocmds(
        "User",
        { pattern = "GitRemotesChanged", modeline = false }
      )
    end
    reopen()
  end
  local function input(lease, prompt, default, callback)
    return lease:input(
      { prompt = prompt, default = default, cwd = cwd },
      function(value)
        if value and vim.trim(value) ~= "" then
          return callback(vim.trim(value))
        else
          reopen()
        end
      end
    )
  end
  local handlers = {
    ["Remove remote"] = function(row, lease)
      vim.ui.select(
        { "Cancel", "Remove " .. row.name },
        { prompt = "Remove remote and its tracking refs?" },
        lease:callback(function(_, index)
          if index == 2 then
            change(
              { "remote", "remove", "--", row.name },
              "Removed remote: " .. row.name
            )
          else
            reopen()
          end
        end)
      )
      return true
    end,
    ["Rename remote"] = function(row, lease)
      return input(lease, "Rename remote: ", row.name, function(name)
        change(
          { "remote", "rename", "--", row.name, name },
          "Renamed remote: " .. row.name .. " → " .. name
        )
      end)
    end,
    ["Replace URL"] = function(row, lease)
      return input(
        lease,
        "Replace " .. row.name .. " " .. row.kind .. " URL: ",
        row.url,
        function(url)
          change(
            M.replace_args(row, url),
            "Updated " .. row.name .. " " .. row.kind .. " URL"
          )
        end
      )
    end,
    ["HTTP → SSH"] = function(row, lease)
      local _, conversion_err = M.to_ssh(row.url, "git")
      if conversion_err then
        tell(conversion_err, vim.log.levels.WARN)
        reopen()
        return
      end
      return input(
        lease,
        "SSH user (provider transport user): ",
        "git",
        function(user)
          local url, user_err = M.to_ssh(row.url, user)
          if not url then
            tell(user_err, vim.log.levels.WARN)
            reopen()
            return
          end
          return input(lease, "SSH URL: ", url, function(value)
            change(
              M.replace_args(row, value),
              "Converted " .. row.name .. " " .. row.kind .. " URL to SSH"
            )
          end)
        end
      )
    end,
  }
  local function run(action, row)
    local accepted = scheduler.write(action, cwd, function(lease)
      return handlers[action](row, lease)
    end)
    if not accepted then
      reopen()
    end
  end
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local function perform(prompt_bufnr, action)
    local selection = action_state.get_selected_entry()
    if not selection then
      return
    end
    actions.close(prompt_bufnr)
    vim.schedule(function()
      if action then
        run(action, selection.value)
      else
        vim.ui.select(
          { "Rename remote", "Replace URL", "HTTP → SSH", "Remove remote" },
          {
            prompt = selection.value.name
              .. " ("
              .. selection.value.kind
              .. ")",
          },
          function(choice)
            if choice then
              run(choice, selection.value)
            else
              reopen()
            end
          end
        )
      end
    end)
  end

  require "moonshine.utils.ui_prevent_mess"()
  local conf = require("telescope.config").values
  require("telescope.pickers")
    .new({ cwd = cwd, initial_mode = "normal" }, {
      prompt_title = "Git remotes: Enter actions · d remove · r rename · u URL · s SSH",
      finder = require("telescope.finders").new_table {
        results = rows,
        entry_maker = function(row)
          local label = row.name .. "  (" .. row.kind .. ")  " .. row.url
          return { value = row, display = label, ordinal = label }
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = false,
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          perform(prompt_bufnr)
        end)
        -- Install after Telescope's defaults, using the RU/EN-aware wrapper.
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(prompt_bufnr) then
            return
          end
          for key, action in pairs {
            d = "Remove remote",
            r = "Rename remote",
            u = "Replace URL",
            s = "HTTP → SSH",
          } do
            map("n", key, function()
              perform(prompt_bufnr, action)
            end, { buffer = prompt_bufnr, desc = action })
          end
        end)
        return true
      end,
    })
    :find()
end

return M
