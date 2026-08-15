local MiniDiff = require "mini.diff"
local notify = require "configs.notify"

local M = {}

local LARGE_BYTES = 100 * 1024
local COMMIT_LIMIT = 300

---@class minidiff.ReviewFile
---@field status string
---@field kind string
---@field path string
---@field old_path string|nil
---@field label string
---@field clickable boolean
---@field binary boolean
---@field large boolean
---@field size integer
---@field additions string
---@field deletions string
---@field stats string

---@class minidiff.ReviewSession
---@field cwd string
---@field old_name string
---@field new_name string
---@field old_sha string
---@field new_sha string
---@field files minidiff.ReviewFile[]
---@field buffers table<string, integer>
---@field confirmed table<string, boolean>
---@field target_win integer|nil
---@field trouble_win integer|nil

---@type minidiff.ReviewSession|nil
local session

--- True while we are tearing down on purpose, so WinClosed does not prompt again.
local finishing = false

local function bottom_close()
  M.finish_review()
end

function M.session()
  return session
end

---@param args string[]
---@param cwd? string
---@return string|nil, string|nil
local function git(args, cwd)
  cwd = cwd or (session and session.cwd) or vim.fn.getcwd()
  local cmd = { "git", "-C", cwd }
  vim.list_extend(cmd, args)
  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 then
    local err = vim.trim((result.stderr or "") ~= "" and result.stderr or ("git exited " .. result.code))
    return nil, err
  end
  return result.stdout or "", nil
end

---@return string|nil, string|nil
local function git_root()
  local dir = vim.fn.expand "%:p:h"
  if dir == "" or vim.fn.isdirectory(dir) == 0 then
    dir = vim.fn.getcwd()
  end
  local out, err = git({ "rev-parse", "--show-toplevel" }, dir)
  if not out then
    return nil, err
  end
  return vim.trim(out), nil
end

---@param ref string
---@param cwd string
---@return string|nil, string|nil
local function rev_parse(ref, cwd)
  local out, err = git({ "rev-parse", "--verify", ref .. "^{commit}" }, cwd)
  if not out then
    return nil, err
  end
  return vim.trim(out), nil
end

---@param bytes integer
---@return string
local function human_size(bytes)
  if bytes < 1024 then
    return bytes .. " B"
  end
  if bytes < 1024 * 1024 then
    return string.format("%.1f KB", bytes / 1024)
  end
  return string.format("%.1f MB", bytes / (1024 * 1024))
end

---@param rest string
---@return string, string
local function split_rename_path(rest)
  local prefix, old, new, suffix = rest:match "^(.*){(.*) => (.*)}(.*)$"
  if prefix then
    return prefix .. old .. suffix, prefix .. new .. suffix
  end
  local left, right = rest:match "^(.*) => (.*)$"
  return left or rest, right or rest
end

---@param stdout string
---@return table<string, { additions: string, deletions: string }>
local function parse_numstat(stdout)
  local by_path = {}
  for _, line in ipairs(vim.split(stdout, "\n", { trimempty = true })) do
    local added, deleted, rest = line:match "^([-%d]+)\t([-%d]+)\t(.*)$"
    if added and rest then
      local info = { additions = added, deletions = deleted }
      if rest:find(" => ", 1, true) then
        local old_path, new_path = split_rename_path(rest)
        by_path[old_path] = info
        by_path[new_path] = info
      else
        by_path[rest] = info
      end
    end
  end
  return by_path
end

---@param sha string
---@param path string
---@param cwd string
---@return integer
local function blob_size(sha, path, cwd)
  local out = git({ "cat-file", "-s", sha .. ":" .. path }, cwd)
  return tonumber(out and vim.trim(out) or "") or 0
end

---@param text string
---@return string[]
local function split_lines(text)
  if text == "" then
    return {}
  end
  local lines = vim.split(text, "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end
  return lines
end

---@return integer|nil
local function current_review_win()
  local ok, View = pcall(require, "trouble.view")
  if not ok then
    return nil
  end
  local found = View.get { mode = "minidiff_review", open = true }
  local entry = found and found[#found]
  local win = entry and entry.view and entry.view.win and entry.view.win.win
  if win and vim.api.nvim_win_is_valid(win) then
    return win
  end
end

local function sync_review_win()
  if not session then
    return
  end
  local win = current_review_win()
  if win then
    session.trouble_win = win
  end
end

local function open_review_view()
  require("trouble").open { mode = "minidiff_review", focus = true }
  vim.schedule(sync_review_win)
end

local function close_review_view()
  require("utils.close_trouble").close_mode "minidiff_review"
end

local function wipe_buffers(buffers)
  require("configs.barbar_api").close_buffers(buffers)
end

---@param opts? { force?: boolean }
---@return boolean
function M.finish_review(opts)
  opts = opts or {}
  if finishing then
    return true
  end
  local trouble = require "trouble"
  if not session then
    finishing = true
    close_review_view()
    finishing = false
    return true
  end
  if not opts.force then
    notify.send("MiniDiff review", "Firstly quit review by pressing 'q' in file list", vim.log.levels.WARN)
    if not trouble.is_open "minidiff_review" then
      open_review_view()
    else
      sync_review_win()
    end
    return false
  end
  finishing = true
  close_review_view()
  local buffers = session.buffers
  session = nil
  wipe_buffers(buffers)
  if _G.bottom_component_callback_close == bottom_close then
    _G.bottom_component_callback_close = function() end
  end
  vim.schedule(close_review_view)
  vim.defer_fn(close_review_view, 50)
  finishing = false
  return true
end

function M.cleanup()
  M.finish_review { force = true }
end

---@param file minidiff.ReviewFile
---@return boolean
local function confirm_heavy(file)
  if not file.binary and not file.large then
    return true
  end
  if session.confirmed[file.path] then
    return true
  end
  local reasons = {}
  if file.binary then
    table.insert(reasons, "binary")
  end
  if file.large then
    table.insert(reasons, "large")
  end
  local msg = string.format("Open %s file %s (%s)?", table.concat(reasons, " and "), file.path, human_size(file.size))
  if vim.fn.confirm(msg, "&Yes\n&No", 2) ~= 1 then
    return false
  end
  session.confirmed[file.path] = true
  return true
end

---@param name string
---@param skip? integer
---@return boolean
local function name_in_use(name, skip)
  local abs = vim.fs.normalize(vim.fn.fnamemodify(name, ":p"))
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= skip and vim.api.nvim_buf_is_valid(b) then
      local existing = vim.api.nvim_buf_get_name(b)
      if existing ~= "" and vim.fs.normalize(existing) == abs then
        return true
      end
    end
  end
  return false
end

---@param file minidiff.ReviewFile
---@param buf integer
---@return string
local function review_buf_name(file, buf)
  local full = vim.fs.normalize(session.cwd .. "/" .. file.path)
  if not name_in_use(full, buf) then
    return full
  end
  local fname = vim.fn.fnamemodify(file.path, ":t")
  local alt = "review-" .. fname
  if not name_in_use(alt, buf) then
    return alt
  end
  local i = 2
  while name_in_use("review-" .. i .. "-" .. fname, buf) do
    i = i + 1
  end
  return "review-" .. i .. "-" .. fname
end

---@param buf integer
---@param path string
---@param lines string[]
local function apply_review_highlight(buf, path, lines)
  local ft = vim.filetype.match { filename = path, contents = lines } or ""
  if ft == "" then
    return
  end
  -- FileType/ftplugin often call vim.treesitter.start() on the current buffer.
  vim.api.nvim_buf_call(buf, function()
    vim.bo.filetype = ft
  end)
  local lang = vim.treesitter.language.get_lang(ft)
  if lang and pcall(vim.treesitter.start, buf, lang) then
    return
  end
  vim.bo[buf].syntax = ft
end

---@param buf integer
local function lock_review_buf(buf)
  vim.bo[buf].buftype = ""
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = true
  vim.bo[buf].swapfile = false
  vim.bo[buf].undofile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  vim.bo[buf].modified = false
  vim.api.nvim_create_autocmd({ "BufWriteCmd", "FileWriteCmd", "FileAppendCmd" }, {
    buffer = buf,
    callback = function()
      notify.send("MiniDiff review", "Review buffers cannot be saved", vim.log.levels.WARN)
    end,
  })
end

---@param file minidiff.ReviewFile
---@return integer|nil
local function ensure_buf(file)
  local existing = session.buffers[file.path]
  if existing and vim.api.nvim_buf_is_valid(existing) then
    return existing
  end

  local new_text = ""
  if file.kind ~= "D" then
    local out, err = git { "--no-pager", "show", session.new_sha .. ":" .. file.path }
    if not out then
      notify.send("MiniDiff review", err or "git show failed", vim.log.levels.ERROR)
      return nil
    end
    new_text = out
  end

  local old_text = ""
  local old_path = file.old_path or file.path
  if file.kind ~= "A" then
    local out = git { "--no-pager", "show", session.old_sha .. ":" .. old_path }
    old_text = out or ""
  end

  if new_text:find("\0", 1, true) or old_text:find("\0", 1, true) then
    local stub = string.format("-- binary file (%s) --", human_size(file.size))
    new_text = stub
    old_text = stub
  end

  local lines = split_lines(new_text)
  local buf = vim.api.nvim_create_buf(true, false)
  session.buffers[file.path] = buf

  vim.b[buf].minidiff_review = true
  vim.b[buf].minidiff_config = {
    source = MiniDiff.gen_source.none(),
    options = {
      linematch = 60,
      wrap_goto = true,
    },
  }

  vim.bo[buf].buftype = ""
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = true
  vim.bo[buf].swapfile = false
  vim.bo[buf].undofile = false
  vim.bo[buf].modifiable = true
  vim.bo[buf].readonly = false

  pcall(vim.api.nvim_buf_set_name, buf, review_buf_name(file, buf))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  apply_review_highlight(buf, file.path, lines)

  MiniDiff.enable(buf)
  if MiniDiff.get_buf_data(buf) == nil then
    session.buffers[file.path] = nil
    require("configs.barbar_api").close_buffer(buf)
    notify.send("MiniDiff review", "Could not enable mini.diff on " .. file.path, vim.log.levels.ERROR)
    return nil
  end
  MiniDiff.set_ref_text(buf, split_lines(old_text))

  lock_review_buf(buf)

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      if session then
        session.buffers[file.path] = nil
      end
    end,
  })

  return buf
end

---@return integer|nil
local function usable_editor_win()
  local skip_ft = {}
  for _, ft in ipairs(require "utils.technical_ui_filetypes") do
    skip_ft[ft] = true
  end

  local function ok(win)
    if not vim.api.nvim_win_is_valid(win) then
      return false
    end
    if vim.w[win].trouble then
      return false
    end
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative ~= "" then
      return false
    end
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.b[buf].minidiff_review then
      return true
    end
    return not skip_ft[vim.bo[buf].filetype]
  end

  if session and session.target_win and ok(session.target_win) then
    return session.target_win
  end

  local wins = vim.api.nvim_list_wins()
  table.insert(wins, 1, vim.api.nvim_get_current_win())
  for _, win in ipairs(wins) do
    if ok(win) then
      return win
    end
  end
end

---@return integer|nil
local function window_showing(buf)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and not vim.w[win].trouble then
      if vim.api.nvim_win_get_buf(win) == buf then
        return win
      end
    end
  end
end

---@param _view table
---@param item table
function M.jump(_view, item)
  local file = item and item.item
  if not file or not session then
    return
  end
  if not file.clickable then
    notify.send("MiniDiff review", file.label .. " is listed only (not openable)", vim.log.levels.INFO)
    return
  end
  if not confirm_heavy(file) then
    return
  end
  local buf = ensure_buf(file)
  if not buf then
    return
  end

  local win = window_showing(buf) or usable_editor_win()
  if not win then
    local prev = vim.fn.win_getid(vim.fn.winnr "#")
    if prev ~= 0 and vim.api.nvim_win_is_valid(prev) and not vim.w[prev].trouble then
      win = prev
    end
  end
  if not win then
    vim.cmd "aboveleft split"
    win = vim.api.nvim_get_current_win()
  end
  session.target_win = win
  if vim.api.nvim_win_get_buf(win) ~= buf then
    vim.api.nvim_win_set_buf(win, buf)
  end
  vim.api.nvim_set_current_win(win)
  local ft = vim.bo[buf].filetype
  if ft ~= "" then
    local lang = vim.treesitter.language.get_lang(ft)
    if lang then
      pcall(vim.treesitter.start, buf, lang)
    end
  end
end

function M.trouble_items()
  local Item = require "trouble.item"
  if not session then
    return {}
  end
  local items = {}
  for _, file in ipairs(session.files) do
    items[#items + 1] = Item.new {
      filename = file.path,
      source = "minidiff_review",
      pos = { 1, 0 },
      item = file,
    }
  end
  Item.add_id(items, { "filename" })
  return items
end

---@param old_name string
---@param new_name string
---@param cwd string
local function start_session(old_name, new_name, cwd)
  local old_sha, old_err = rev_parse(old_name, cwd)
  if not old_sha then
    notify.send("MiniDiff review", old_err or ("Invalid ref: " .. old_name), vim.log.levels.ERROR)
    return
  end
  local new_sha, new_err = rev_parse(new_name, cwd)
  if not new_sha then
    notify.send("MiniDiff review", new_err or ("Invalid ref: " .. new_name), vim.log.levels.ERROR)
    return
  end
  if old_sha == new_sha then
    notify.send("MiniDiff review", "Both refs resolve to the same commit", vim.log.levels.WARN)
    return
  end

  local status_out, status_err = git({ "diff", "--name-status", "-M", old_sha, new_sha }, cwd)
  if not status_out then
    notify.send("MiniDiff review", status_err or "git diff failed", vim.log.levels.ERROR)
    return
  end
  local numstat_out = git({ "diff", "--numstat", "-M", old_sha, new_sha }, cwd) or ""
  local stats = parse_numstat(numstat_out)

  local files = {}
  for _, line in ipairs(vim.split(status_out, "\n", { trimempty = true })) do
    local parts = vim.split(line, "\t", { plain = true })
    local status = parts[1]
    if status and parts[2] then
      local kind = status:sub(1, 1)
      local path, old_path, label
      if kind == "R" or kind == "C" then
        old_path = parts[2]
        path = parts[3] or parts[2]
        label = old_path .. " → " .. path
      else
        path = parts[2]
        label = path
      end
      local st = stats[path] or stats[old_path or path] or { additions = "0", deletions = "0" }
      local binary = st.additions == "-" and st.deletions == "-"
      local size = 0
      if kind ~= "D" then
        size = blob_size(new_sha, path, cwd)
      elseif old_path or path then
        size = blob_size(old_sha, old_path or path, cwd)
      end
      local large = size > LARGE_BYTES
      local clickable = kind == "M" or kind == "A" or kind == "T"
      local stats_text
      if binary then
        stats_text = "binary"
      elseif kind == "D" then
        stats_text = ""
      else
        stats_text = string.format("+%s -%s", st.additions, st.deletions)
      end
      files[#files + 1] = {
        status = status,
        kind = kind,
        path = path,
        old_path = old_path,
        label = label,
        clickable = clickable,
        binary = binary,
        large = large,
        size = size,
        additions = st.additions,
        deletions = st.deletions,
        stats = stats_text,
      }
    end
  end

  if #files == 0 then
    notify.send("MiniDiff review", "No file changes between " .. old_name .. " and " .. new_name, vim.log.levels.INFO)
    return
  end

  M.finish_review { force = true }
  require("utils.close_trouble")()
  if _G.bottom_component_callback_close then
    pcall(_G.bottom_component_callback_close)
  end

  session = {
    cwd = cwd,
    old_name = old_name,
    new_name = new_name,
    old_sha = old_sha,
    new_sha = new_sha,
    files = files,
    buffers = {},
    confirmed = {},
    target_win = nil,
    trouble_win = nil,
  }
  session.target_win = usable_editor_win()
  _G.bottom_component_callback_close = bottom_close

  open_review_view()
end

---@param kind string
---@param value string
---@param text string
---@return table
local function make_ref_entry(kind, value, text)
  return {
    kind = kind,
    value = value,
    text = text,
    ordinal = kind .. " " .. value .. " " .. text,
  }
end

---@param cwd string
---@return table[]
local function collect_refs(cwd)
  local refs = { make_ref_entry("HEAD", "HEAD", "current HEAD") }

  local seen = { HEAD = true }
  local for_each, err = git({
    "for-each-ref",
    "--sort=-committerdate",
    "--format=%(refname:short)%09%(objectname:short)%09%(refname)",
    "refs/heads",
    "refs/remotes",
    "refs/tags",
  }, cwd)
  if not for_each then
    notify.send("MiniDiff review", err or "failed to list refs", vim.log.levels.ERROR)
    return refs
  end

  for _, line in ipairs(vim.split(for_each, "\n", { trimempty = true })) do
    local name, short, full = line:match "^([^\t]+)\t([^\t]+)\t(.*)$"
    if name and not seen[name] then
      seen[name] = true
      local kind = "branch"
      if full:find "^refs/remotes/" then
        kind = "remote"
      elseif full:find "^refs/tags/" then
        kind = "tag"
      end
      refs[#refs + 1] = make_ref_entry(kind, name, short)
    end
  end

  local log = git({ "log", "--pretty=format:%h\t%s", "-n", tostring(COMMIT_LIMIT) }, cwd) or ""
  for _, line in ipairs(vim.split(log, "\n", { trimempty = true })) do
    local hash, subject = line:match "^([^\t]+)\t(.*)$"
    if hash then
      refs[#refs + 1] = make_ref_entry("commit", hash, subject or "")
    end
  end

  return refs
end

---@param title string
---@param cwd string
---@param on_pick fun(ref: string)
local function pick_ref(title, cwd, on_pick)
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local previewers = require "telescope.previewers"
  local putils = require "telescope.previewers.utils"
  local entry_display = require "telescope.pickers.entry_display"

  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = 8 },
      { width = 32 },
      { remaining = true },
    },
  }

  local kind_hl = {
    HEAD = "TelescopeResultsIdentifier",
    branch = "TelescopeResultsConstant",
    remote = "TelescopeResultsNumber",
    tag = "TelescopeResultsSpecialComment",
    commit = "TelescopeResultsComment",
  }

  pickers
    .new({
      cwd = cwd,
      initial_mode = "normal",
    }, {
      prompt_title = title,
      finder = finders.new_table {
        results = collect_refs(cwd),
        entry_maker = function(item)
          return {
            value = item.value,
            ordinal = item.ordinal,
            display = function()
              return displayer {
                { item.kind, kind_hl[item.kind] or "TelescopeResultsComment" },
                { item.value, "TelescopeResultsIdentifier" },
                { item.text, "TelescopeResultsComment" },
              }
            end,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = previewers.new_buffer_previewer {
        title = "Ref log",
        define_preview = function(self, entry)
          putils.job_maker(
            {
              "git",
              "-C",
              cwd,
              "--no-pager",
              "log",
              "--oneline",
              "-n",
              "40",
              entry.value,
            },
            self.state.bufnr,
            {
              callback = function(bufnr)
                if vim.api.nvim_buf_is_valid(bufnr) then
                  putils.highlighter(bufnr, "gitcommit", {})
                end
              end,
            }
          )
        end,
      },
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection and selection.value then
            on_pick(selection.value)
          end
        end)
        return true
      end,
    })
    :find()
end

function M.open_picker()
  local is_codediff_tab = require "utils.is_codediff_tab"
  if is_codediff_tab() then
    notify.send("MiniDiff review", "Cannot open: CodeDiff is current tabpage", vim.log.levels.ERROR)
    return
  end

  local cwd, err = git_root()
  if not cwd then
    notify.send("MiniDiff review", err or "Not a git repository", vim.log.levels.ERROR)
    return
  end

  pick_ref("Compare from (old)", cwd, function(old_name)
    vim.schedule(function()
      pick_ref("Compare to (new)", cwd, function(new_name)
        start_session(old_name, new_name, cwd)
      end)
    end)
  end)
end

function M.setup()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("MiniDiffReviewNoLsp", { clear = true }),
    callback = function(ev)
      if not vim.b[ev.buf].minidiff_review then
        return
      end
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(ev.buf) then
          return
        end
        for _, client in ipairs(vim.lsp.get_clients { bufnr = ev.buf }) do
          pcall(vim.lsp.buf_detach_client, ev.buf, client.id)
        end
      end)
    end,
  })

  local guard = vim.api.nvim_create_augroup("MiniDiffReviewTroubleGuard", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = guard,
    pattern = "trouble",
    callback = function()
      if session then
        vim.schedule(sync_review_win)
      end
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = guard,
    callback = function(ev)
      if finishing or not session then
        return
      end
      local closed = tonumber(ev.match)
      if not closed or closed ~= session.trouble_win then
        return
      end
      session.trouble_win = nil
      if vim.v.exiting ~= vim.NIL then
        M.finish_review { force = true }
        return
      end
      vim.schedule(function()
        if finishing or not session then
          return
        end
        if require("trouble").is_open "minidiff_review" then
          sync_review_win()
          return
        end
        M.finish_review()
      end)
    end,
  })

  vim.api.nvim_create_user_command("MiniDiffReview", function()
    M.open_picker()
  end, { desc = "Compare two git refs in a mini.diff review" })
end

return M
