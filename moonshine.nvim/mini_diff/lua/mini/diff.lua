--- *mini.diff* Work with diff hunks
---
--- MIT License Copyright (c) 2024 Evgeni Chasnovski

--- Features:
---
--- - Visualize difference between buffer text and its configurable reference
---   interactively (updates as you type). This is done per line showing whether
---   it is inside added, changed, or deleted part of difference (called hunk).
---   Visualization can be with customizable colored signs or line numbers.
---
--- - Special toggleable overlay view with more hunk details inside text area.
---   See |MiniDiff.toggle_overlay()|.
---
--- - Completely configurable per buffer source(s) of reference text used to keep
---   it up to date and define interactions with it. Can be array of sources which
---   are attempted to attach in order. See |MiniDiff-source-specification|.
---   By default uses Git source. See |MiniDiff.gen_source.git()|.
---
--- - Configurable mappings to manage diff hunks:
---     - Apply and reset hunks inside region (selected visually or with
---       a dot-repeatable operator).
---     - "Hunk range under cursor" textobject to be used as operator target.
---     - Navigate to first/previous/next/last hunk. See |MiniDiff.goto_hunk()|.
---
--- What it doesn't do:
---
--- - Provide functionality to work directly with Git outside of visualizing
---   and staging (applying) hunks with (default) Git source. In particular,
---   unstaging hunks is not supported. See |MiniDiff.gen_source.git()|.
---
--- Sources with more details:
--- - |MiniDiff-overview|
--- - |MiniDiff-source-specification|
--- - |MiniDiff-hunk-specification|
--- - |MiniDiff-diff-summary|
---
--- # Setup ~
---
--- This module needs a setup with `require('mini.diff').setup({})` (replace
--- `{}` with your `config` table). It will create global Lua table `MiniDiff`
--- which you can use for scripting or manually (with `:lua MiniDiff.*`).
---
--- See |MiniDiff.config| for `config` structure and default values.
---
--- You can override runtime config settings locally to buffer inside
--- `vim.b.minidiff_config` which should have same structure as
--- `MiniDiff.config`. See |mini.nvim-buffer-local-config| for more details.
---
--- # Comparisons ~
---
--- - [lewis6991/gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim):
---     - Main inspiration for this module, so there are many similarities.
---     - Can display only Git hunks, while this module has extensible design.
---     - Provides more functionality to work with Git outside of hunks.
---       This module does not (by design).
---
--- # Highlight groups ~
--- *MiniDiff-hl-groups*
---
--- - `MiniDiffSignAdd`        - "add" hunk lines visualization.
--- - `MiniDiffSignChange`     - "change" hunk lines visualization.
--- - `MiniDiffSignDelete`     - "delete" hunk lines visualization.
--- - `MiniDiffOverAdd`        - added buffer text shown in overlay.
--- - `MiniDiffOverChange`     - changed reference text shown in overlay.
--- - `MiniDiffOverChangeBuf`  - changed buffer text shown in overlay.
--- - `MiniDiffOverContext`    - context of a change shown in reference overlay.
--- - `MiniDiffOverContextBuf` - context of a change shown in buffer overlay.
--- - `MiniDiffOverDelete`     - deleted reference text shown in overlay.
---
--- To change any highlight group, set it directly with |nvim_set_hl()|.
---
--- # Disabling ~
---
--- To temporarily disable features without relying on |MiniDiff.disable()|,
--- set `vim.g.minidiff_disable` (globally) or `vim.b.minidiff_disable` (for
--- a buffer) to `true`. Considering high number of different scenarios and
--- customization intentions, writing exact rules for disabling module's
--- functionality is left to user.
--- See |mini.nvim-disabling-recipes| for common recipes.
---@tag MiniDiff

--- # Diffs and hunks ~
---
--- The "diff" (short for "difference") is a result of computing how two text
--- strings differ from one another. This is done on per line basis, i.e. the
--- goal is to compute sequences of lines common to both files, interspersed
--- with groups of differing lines (called "hunks").
---
--- Although computing diff is a general concept (used on its own, in Git, etc.),
--- this module computes difference between current text in a buffer and some
--- reference text which is kept up to date specifically for that buffer.
--- For example, default reference text is computed as file content in Git index.
--- This can be customized in `config.source` (see |MiniDiff-source-specification|).
---
--- # Hunk specification ~
--- *MiniDiff-hunk-specification*
---
--- Hunk describes two sets (one from buffer text, one - from reference) of
--- consecutive lines which are different. In this module hunk is stored as
--- a table with the following fields:
---
--- - <buf_start> `(number)` - start of hunk buffer lines. First line is 1.
---   Can be 0 if first reference lines are deleted.
---
--- - <buf_count> `(number)` - number of consecutive buffer lines. Can be 0 in
---   case reference lines are deleted.
---
--- - <ref_start> `(number)` - start of hunk reference lines. First line is 1.
---   Can be 0 if lines are added before first reference line.
---
--- - <ref_count> `(number)` - number of consecutive reference lines. Can be 0 in
---   case buffer lines are added.
---
--- - <type> `(string)` - hunk type. Can be one of:
---     - "add" - lines are present in buffer but absent in reference.
---     - "change" - lines are present in both buffer and reference.
---     - "delete" - lines are absent in buffer but present in reference.
---
--- # Life cycle ~
---
--- - When entering proper (not already enabled, valid, showing text) buffer,
---   it is attempted to be enabled for diff processing.
--- - During enabling, attempt attaching the source. This should set up how
---   reference text is kept up to date.
--- - On every text change, diff computation is scheduled in debounced fashion
---   after customizable delay (200 ms by default).
--- - After the diff is computed, do the following:
---     - Update visualization based on configurable style: either by placing
---       colored text in sign column or coloring line numbers. Colors for both
---       styles are defined per hunk type in corresponding `MiniDiffSign*`
---       highlight group (see |mini.diff|) and sign text for "sign" style can
---       be configured in `view.signs` of |MiniDiff.config|.
---     - Update overlay view (if it is enabled).
---     - Update `vim.b.minidiff_summary` and `vim.b.minidiff_summary_string`
---       buffer-local variables. These can be used, for example, in statusline.
---     - *MiniDiff-update-event* Trigger `MiniDiffUpdated` `User` event.
---       See |MiniDiff-diff-summary| for example of how to use it.
---
--- Notes:
--- - Use |:edit| to reset (disable and re-enable) current buffer.
--- - To work with BOM bytes, set |'bomb'| and have `ucs-bom` in |'fileencodings'|.
---
--- # Overlay ~
---
--- Along with basic visualization, there is a special view called "overlay".
--- Although it is meant for temporary overview of diff details and can be
--- manually toggled via |MiniDiff.toggle_overlay()|, text can be changed with
--- overlay reacting accordingly.
---
--- It shows more diff details inside text area:
---
--- - Added buffer lines are highlighted with `MiniDiffOverAdd` highlight group.
---
--- - Deleted reference lines are shown as virtual lines and highlighted with
---   `MiniDiffOverDelete` highlight group.
---
--- - "Change" hunks with equal number of buffer/reference lines show "word diff".
---   This is usually the case when `options.linematch` is enabled (as by default).
---   Reference line is shown next to its buffer counterpart. Changed parts are
---   highlighted with `MiniDiffOverChange` and `MiniDiffOverChangeBuf` in reference
---   and buffer lines. The rest of lines have `MiniDiffOverContext`
---   and `MiniDiffOverContextBuf` highlighting.
---
---   Change with unequal number of buffer/reference lines is shown with reference
---   part as virtual lines highlighted with `MiniDiffOverChange` group.
---   Corresponding buffer lines are treated as context for the change and are
---   highlighted with `MiniDiffOverContextBuf` group.
---
--- Notes:
--- - Word diff has non-zero context width. This means if changed characters
---   are close enough, whole range between them is also colored. This usually
---   reduces visual noise.
--- - Virtual lines above line 1 (like deleted or changed lines) need manual
---   scroll to become visible (with |CTRL-Y|).
---
--- # Mappings ~
---
--- This module provides mappings for common actions with diffs, like:
--- - Apply and reset hunks.
--- - "Hunk range under cursor" textobject.
--- - Go to first/previous/next/last hunk range.
---
--- Examples:
--- - `vip` followed by `gh` / `gH` applies/resets hunks inside current paragraph.
---   Same can be achieved in operator form `ghip` / `gHip`, which has the
---   advantage of being dot-repeatable (see |single-repeat|).
--- - `gh_` / `gH_` applies/resets current line (even if it is not a full hunk).
--- - `ghgh` / `gHgh` applies/resets hunk range under cursor.
--- - `dgh` deletes hunk range under cursor.
--- - `[H` / `[h` / `]h` / `]H` navigate cursor to the first / previous / next / last
---   hunk range of the current buffer.
---
--- Mappings for some functionality are assumed to be done manually.
--- See |MiniDiff.operator()|.
---
--- # Buffer-local variables ~
--- *MiniDiff-diff-summary*
---
--- Each enabled buffer has the following buffer-local variables which can be
--- used in custom statusline to show an overview of hunks in current buffer:
---
--- - `vim.b.minidiff_summary` is a table with the following fields:
---     - `source_name` - name of the active source. This is the only present field
---       if buffer's reference text is not (yet) set.
---     - `n_ranges` - number of hunk ranges (sequences of contiguous hunks).
---     - `add` - number of added lines.
---     - `change` - number of changed lines.
---     - `delete` - number of deleted lines.
---
--- - `vim.b.minidiff_summary_string` is a string representation of summary
---   with a fixed format. Empty string if there is no reference text (yet).
---   It is expected to be used as is. To achieve different formatting, use
---   `vim.b.minidiff_summary` to construct one. The best way to do this is by
---   overriding `vim.b.minidiff_summary_string` inside |MiniDiff-update-event|: >lua
---
---   local format_summary = function(data)
---     local summary = vim.b[data.buf].minidiff_summary
---     local t = {}
---     if summary.add > 0 then table.insert(t, '+' .. summary.add) end
---     if summary.change > 0 then table.insert(t, '~' .. summary.change) end
---     if summary.delete > 0 then table.insert(t, '-' .. summary.delete) end
---     vim.b[data.buf].minidiff_summary_string = table.concat(t, ' ')
---   end
---   local au_opts = { pattern = 'MiniDiffUpdated', callback = format_summary }
---   vim.api.nvim_create_autocmd('User', au_opts)
--- <
---@tag MiniDiff-overview

---@alias __diff_buf_id number Target buffer identifier. Default: 0 for current buffer.

---@diagnostic disable:undefined-field
---@diagnostic disable:discard-returns
---@diagnostic disable:unused-local
---@diagnostic disable:cast-local-type
---@diagnostic disable:undefined-doc-name
---@diagnostic disable:luadoc-miss-type-name

-- Module definition ==========================================================
local MiniDiff = {}
local H = {}

--- Module setup
---
---@param config table|nil Module config table. See |MiniDiff.config|.
---
---@usage >lua
---   require('mini.diff').setup() -- use default config
---   -- OR
---   require('mini.diff').setup({}) -- replace {} with your config table
--- <
MiniDiff.setup = function(config)
  -- Export module
  _G.MiniDiff = MiniDiff

  -- Setup config
  config = H.setup_config(config)

  -- Apply config
  H.apply_config(config)

  -- Define behavior
  H.create_autocommands()
  for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
    H.auto_enable({ buf = buf_id })
  end

  -- Create default highlighting
  H.create_default_hl()
end

--stylua: ignore
--- Defaults ~
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---@text # View ~
---
--- `config.view` contains settings for how diff hunks are visualized.
--- Example of using custom signs: >lua
---
---   require('mini.diff').setup({
---     view = {
---       style = 'sign',
---       signs = { add = '+', change = '~', delete = '-' },
---     },
---   })
--- <
--- `view.style` is a string defining visualization style. Can be one of "sign"
--- (as a colored sign in a |sign-column|) or "number" (colored line number).
--- Default: "number" if |'number'| option is enabled, "sign" otherwise.
--- Note: with "sign" style it is better to have |'signcolumn'| always shown.
---
--- `view.signs` is a table with one or two character strings used as signs for
--- corresponding ("add", "change", "delete") hunks.
--- Default: all hunks use "▒" character resulting in a contiguous colored lines.
---
--- `view.priority` is a number with priority used for visualization and
--- overlay |extmarks|.
--- Default: 199 which is one less than `user` in |vim.hl.priorities| (on Neovim<0.11
--- see |vim.hl.priorities|) to have higher priority than automated
--- extmarks but not as in user enabled ones.
---
--- # Source ~
--- *MiniDiff-source-specification*
---
--- `config.source` is a table with single source or array of them. Single source
--- defines how reference text is managed in a particular buffer. Sources in array
--- are attempted to attach in order; call |MiniDiff.disable()| if none attaches.
---
--- A single source table can have the following fields:
---
--- - <attach> `(function)` - callable which defines how and when reference text
---   is updated inside a particular buffer. It is used inside |MiniDiff.enable()|
---   with a buffer identifier as a single argument.
---
---   Should execute logic which results into calling |MiniDiff.set_ref_text()|
---   when reference text for buffer needs to be updated. Like inside callback
---   for an |autocommand| or file watcher (see |watch-file|).
---
---   For example, default Git source watches when ".git/index" file is changed
---   and computes reference text as the one from Git index for current file.
---
---   Can return `false` to indicate that attach has failed. If attach fail can
---   not be inferred immediately (for example, due to asynchronous execution),
---   should explicitly call |MiniDiff.fail_attach()| with appropriate arguments.
---   This is important to properly process array of sources.
---
---   No default value, should be always supplied.
---
--- - <name> `(string|nil)` - source name. String `"unknown"` is used if not supplied.
---
--- - <detach> `(function|nil)` - callable with cleanup action to be done when
---   buffer is disabled. It is called inside |MiniDiff.disable()| with a buffer
---   identifier as a single argument.
---
---   If not supplied, nothing is done during detaching.
---
--- - <apply_hunks> `(function|nil)` - callable which defines how hunks are applied.
---   It is called with buffer identifier as first argument and array of hunks
---   (see |MiniDiff-hunk-specification|) as second. It should eventually update
---   reference text: either by explicitly calling |MiniDiff.set_ref_text()| or
---   performing action triggering its call.
---
---   For example, default Git source computes patch based on the hunks and
---   applies it inside file's git repo.
---
---   If not supplied, applying hunks throws an error.
---
--- Default: a single |MiniDiff.gen_source.git()|.
---
--- # Delay ~
---
--- `config.delay` contains settings for delays in asynchronous processes.
---
--- `delay.text_change` is a number (in ms) defining how long to wait after latest
--- text change (in debounced fashion) before updating diff and visualization.
--- Default: 200.
---
--- # Mappings ~
---
--- `config.mappings` contains keys which are mapped during |MiniDiff.setup()|.
---
--- `mappings.apply` keys can be used to apply hunks inside visual/operator region.
--- What exactly "apply hunks" means depends on the source and its `apply_hunks()`.
--- For example, in default Git source it means stage hunks.
---
--- `mappings.reset` keys can be used to reset hunks inside visual/operator region.
--- Reset means replacing buffer text in region with corresponding reference text.
---
--- `mappings.textobject` keys define "hunk range under cursor" textobject
--- which can be used in Operator-pending mode as target for operator (like
--- |d|, |y|, apply/reset hunks, etc.). It is also set up in Visual mode if
--- keys do not conflict with `mappings.apply` and `mappings.reset`.
--- "Hunk range" is used in a sense that contiguous (back-to-back) hunks are
--- considered as parts of a same hunk range.
---
--- `mappings.goto_first` / `mappings.goto_prev` / `mappings.goto_next` /
--- `mappings.goto_last` keys can be used to navigate to first / previous / next /
--- last hunk range in the current buffer.
---
--- # Options ~
---
--- `config.options` contains various customization options.
---
--- `options.algorithm` is a string defining which diff algorithm to use.
--- Default: "histogram". See |vim.text.diff()| (|vim.diff()| on Neovim<=0.11)
--- for possible values.
---
--- `options.indent_heuristic` is a boolean defining whether to use indent
--- heuristic for a (possibly) more naturally aligned hunks.
--- Default: `true`.
---
--- `options.linematch` is a number defining hunk size for which a second
--- stage diff is executed for a better aligned and more granular hunks.
--- Default: 60. See |vim.text.diff()| (|vim.diff()| on Neovim<=0.11) and |'diffopt'|
--- for more details.
---
--- `options.wrap_goto` is a boolean indicating whether to wrap around edges during
--- hunk navigation (with |MiniDiff.goto_hunk()| or `goto_*` mappings). Like if
--- cursor is after the last hunk, going "next" will put cursor on the first hunk.
--- Default: `false`.
MiniDiff.config = {
  -- Options for how hunks are visualized
  view = {
    -- Visualization style. Possible values are 'sign' and 'number'.
    -- Default: 'number' if line numbers are enabled, 'sign' otherwise.
    style = vim.go.number and 'number' or 'sign',

    -- Signs used for hunks with 'sign' view
    signs = { add = '▒', change = '▒', delete = '▒' },

    -- Priority of used visualization extmarks
    priority = 199,
  },

  -- Source(s) for how reference text is computed/updated/etc
  -- Uses content from Git index by default
  source = nil,

  -- Delays (in ms) defining asynchronous processes
  delay = {
    -- How much to wait before update following every text change
    text_change = 200,
  },

  -- Module mappings. Use `''` (empty string) to disable one.
  mappings = {
    -- Apply hunks inside a visual/operator region
    apply = 'gh',

    -- Reset hunks inside a visual/operator region
    reset = 'gH',

    -- Hunk range textobject to be used inside operator
    -- Works also in Visual mode if mapping differs from apply and reset
    textobject = 'gh',

    -- Go to hunk range in corresponding direction
    goto_first = '[H',
    goto_prev = '[h',
    goto_next = ']h',
    goto_last = ']H',
  },

  -- Various options
  options = {
    -- Diff algorithm (see `:h vim.text.diff()`)
    algorithm = 'histogram',

    -- Whether to use "indent heuristic" (see `:h vim.text.diff()`)
    indent_heuristic = true,

    -- The amount of second-stage diff to align lines
    linematch = 60,

    -- Whether to wrap around edges during hunk navigation
    wrap_goto = false,
  },
}
--minidoc_afterlines_end

--- Enable diff processing in buffer
---
---@param buf_id __diff_buf_id
MiniDiff.enable = function(buf_id)
  buf_id = H.validate_buf_id(buf_id)

  -- Don't enable more than once
  if H.is_buf_enabled(buf_id) or H.is_disabled(buf_id) then return end

  -- Ensure buffer is loaded (to have up to date lines returned)
  H.buf_ensure_loaded(buf_id)

  -- Register enabled buffer with cached data for performance
  H.update_buf_cache(buf_id)
  H.states[buf_id] = nil
  H.set_state(buf_id, 'unavailable', 'No reference text available')

  -- Add buffer watchers
  vim.api.nvim_buf_attach(buf_id, false, {
    -- Called on every text change (`:h nvim_buf_lines_event`)
    on_lines = function(_, _, _, from_line, _, to_line)
      local buf_cache = H.cache[buf_id]
      -- Properly detach if diffing is disabled
      if buf_cache == nil then return true end
      H.schedule_diff_update(buf_id, buf_cache.config.delay.text_change)
    end,

    -- Called when buffer content is changed outside of current session
    on_reload = function() H.schedule_diff_update(buf_id, 0) end,

    -- Called when buffer is unloaded from memory (`:h nvim_buf_detach_event`),
    -- **including** `:edit` command
    on_detach = function() MiniDiff.disable(buf_id) end,
  })

  -- Add buffer autocommands
  H.setup_buf_autocommands(buf_id)

  -- Try attaching source after all necessary watchers are set up. It is needed
  -- to still have them set up if first source of many returned `false`.
  local attach_output = H.get_active_source(H.cache[buf_id]).attach(buf_id)
  if attach_output == false then MiniDiff.fail_attach(buf_id) end
end

--- Disable diff processing in buffer
---
---@param buf_id __diff_buf_id
MiniDiff.disable = function(buf_id)
  buf_id = H.validate_buf_id(buf_id)

  local buf_cache = H.cache[buf_id]
  if buf_cache == nil then return end
  H.cache[buf_id] = nil
  require('mini.diff.hunks_cache').clear(buf_id)
  H.bufs_to_update[buf_id] = nil
  H.set_state(buf_id, 'unavailable', 'Diff is not enabled for this buffer')

  pcall(vim.api.nvim_del_augroup_by_id, buf_cache.augroup)
  vim.b[buf_id].minidiff_summary, vim.b[buf_id].minidiff_summary_string = nil, nil
  H.clear_all_diff(buf_id)
  pcall(H.get_active_source(buf_cache).detach, buf_id)
end

--- Toggle diff processing in buffer
---
--- Enable if disabled, disable if enabled.
---
---@param buf_id __diff_buf_id
MiniDiff.toggle = function(buf_id)
  buf_id = H.validate_buf_id(buf_id)
  if H.is_buf_enabled(buf_id) then return MiniDiff.disable(buf_id) end
  return MiniDiff.enable(buf_id)
end

--- Toggle overlay view in buffer
---
---@param buf_id __diff_buf_id
MiniDiff.toggle_overlay = function(buf_id)
  buf_id = H.validate_buf_id(buf_id)
  return require('mini.diff.hunk_mode').toggle_buffer(buf_id, H)
end

--- Export hunks
---
--- Get and convert hunks from current/all buffers. Example of using it: >lua
---
---   -- Set quickfix list from all available hunks
---   vim.fn.setqflist(MiniDiff.export('qf'))
--- <
---@param format string Output format. Currently only `'qf'` value is supported.
---@param opts table|nil Options. Possible fields:
---   - <scope> `(string)` - scope defining from which buffers to use hunks.
---     One of "all" (all enabled buffers) or "current".
---
---@return table Result of export. Depends on the `format`:
---   - If "qf", an array compatible with |setqflist()| and |setloclist()|.
MiniDiff.export = function(format, opts)
  opts = vim.tbl_deep_extend('force', { scope = 'all' }, opts or {})
  if format == 'qf' then return H.export_qf(opts) end
  H.error('`format` should be one of "qf".')
end

--- Get buffer lifecycle state
---
--- Local extension: |MiniDiff.get_buf_state()| returns a cheap, independent
--- snapshot with `status` (loading/updating/ready/unavailable/failed) and optional
--- `reason`. Nil means no lifecycle state is recorded. `MiniDiffStateChanged`
--- User events carry the target buffer in `data.buf` and fire only on changes.
--- Progress includes queued work; synchronous diff computation cannot animate.
MiniDiff.get_buf_state = function(buf_id)
  buf_id = H.validate_buf_id(buf_id)
  local state = H.states[buf_id]
  if state == nil then return nil end
  return { status = state.status, reason = state.reason }
end

--- Get buffer data
---
---@param buf_id __diff_buf_id
---
---@return table|nil Table with buffer diff data or `nil` if buffer is not enabled.
---   Table has the following fields:
---   - <config> `(table)` - config used for this particular buffer.
---   - <hunks> `(table)` - array of hunks. See |MiniDiff-hunk-specification|.
---   - <overlay> `(boolean)` - whether an overlay view is shown.
---   - <ref_text> `(string|nil)` - current value of reference text. Lines are
---     separated with newline character (`'\n'`). Can be `nil` indicating that
---     reference text was not yet set (for example, if source did not yet react).
---   - <summary> `(table)` - overall diff summary. See |MiniDiff-diff-summary|.
MiniDiff.get_buf_data = function(buf_id)
  buf_id = H.validate_buf_id(buf_id)
  local buf_cache = H.cache[buf_id]
  if buf_cache == nil then return nil end
  return vim.deepcopy({
    config = buf_cache.config,
    hunks = buf_cache.hunks,
    overlay = buf_cache.overlay,
    ref_text = buf_cache.ref_text,
    summary = buf_cache.summary,
  })
end

--- Independent HEAD -> index snapshot. `hunks` use index coordinates;
--- `buffer_hunks` are display anchors projected through unsaved buffer edits.
--- The ordinary diff data and all mutation APIs remain index -> buffer only.
MiniDiff.get_staged_data = function(buf_id)
  buf_id = H.validate_buf_id(buf_id)
  local git = H.git_cache[buf_id]
  return git and vim.deepcopy(git.staged) or nil
end

--- Cheap staged readiness snapshot for presentation and action guards.
MiniDiff.get_staged_state = function(buf_id)
  buf_id = H.validate_buf_id(buf_id)
  local git = H.git_cache[buf_id]
  local staged = git and git.staged
  return staged and { status = staged.status, reason = staged.reason } or nil
end

--- Settle queued buffer edits before explicit navigation. Never wait for Git
--- IO or run an action later; reference loading retains its normal guard.
MiniDiff.flush_buf_diff = function(buf_id)
  buf_id = H.validate_buf_id(buf_id)
  local cache, state = H.cache[buf_id], H.states[buf_id]
  if not cache or not cache.has_result or cache.ref_pending or type(cache.ref_text) ~= 'string' then return end
  if state and state.status == 'updating' then H.update_buf_diff_now(buf_id, cache) end
end

--- Display/navigation ranges only. Never pass these to mutation APIs.
MiniDiff.get_navigation_hunk_ranges = function(buf_id)
  buf_id = H.validate_buf_id(buf_id)
  local cache = H.cache[buf_id]
  if not cache then return nil end
  return require('mini.diff.navigation.global_navigation').ranges(buf_id)
end

--- Contiguous hunk ranges
---
--- Adjacent hunks are merged into one range. Same data as used by
--- |MiniDiff.goto_hunk()| and |MiniDiff.textobject()|.
---
---@param buf_id __diff_buf_id
---@return table|nil Array of `{ from = line, to = line }`, or `nil` if not enabled.
MiniDiff.get_contiguous_hunk_ranges = function(buf_id)
  buf_id = H.validate_buf_id(buf_id)
  local buf_cache = H.cache[buf_id]
  if buf_cache == nil then return nil end
  return H.get_contiguous_hunk_ranges(buf_cache.hunks)
end

--- Contiguous hunk range under cursor
---
---@param buf_id __diff_buf_id
---@return table|nil Range `{ from = line, to = line }`
---@return integer|nil 1-based index among contiguous ranges
MiniDiff.get_contiguous_hunk_range_at_cursor = function(buf_id)
  local ranges = MiniDiff.get_contiguous_hunk_ranges(buf_id)
  if ranges == nil then return nil end
  local cur_line = vim.fn.line('.')
  for i, r in ipairs(ranges) do
    if r.from <= cur_line and cur_line <= r.to then return r, i end
  end
end

--- Set reference text for the buffer
---
--- Note: this will call |MiniDiff.enable()| for target buffer if it is not
--- already enabled.
---
---@param buf_id __diff_buf_id
---@param text string|table|nil New reference text. Default: `nil`. Can be:
---   - String with `\n` separating lines.
---   - Array of strings representing lines.
---   - `nil` to unset current reference text (results in no hunks shown).
---
--- Notes:
---   - Empty string `''` and empty array `{}` set empty reference text (whole
---     buffer text is a single "add" hunk). Use `'\n'` or `{ '' }` to set a single
---     empty line as a reference text.
---   - Newline character is appended (if not already there) at the end of the
---     non-empty reference text for better diffs.
MiniDiff.set_ref_text = function(buf_id, text)
  buf_id = H.validate_buf_id(buf_id)
  if type(text) == 'table' then text = table.concat(text, '\n') .. (#text > 0 and '\n' or '') end
  if not (type(text) == 'string' or text == nil) then H.error('`text` should be either string, array, or nil.') end

  -- Enable if not already enabled
  if not H.is_buf_enabled(buf_id) then MiniDiff.enable(buf_id) end
  if not H.is_buf_enabled(buf_id) then H.error('Can not set reference text for not enabled buffer.') end

  -- Appending '\n' makes more intuitive diffs at end-of-file
  if not (text == nil or text == '' or text:sub(-1) == '\n') then text = text .. '\n' end
  if text == nil then
    H.clear_all_diff(buf_id)
    vim.cmd('redraw')
  end

  -- Immediately update diff
  H.cache[buf_id].ref_text = text
  H.cache[buf_id].ref_error = nil
  H.schedule_diff_update(buf_id, 0)
end

--- Generate builtin sources
---
--- This is a table with function elements. Call to actually get source.
--- Examples: >lua
---
---   local diff = require('mini.diff')
---
---   -- Single `save` source
---   diff.setup({ source = diff.gen_source.save() })
---
---   -- Multiple sources (attempted to attach in order)
---   diff.setup({ source = { diff.gen_source.git(), diff.gen_source.save() } })
--- <
MiniDiff.gen_source = {}

--- Git source
---
--- Default source. Uses file text from Git index as reference. This results in:
--- - "Add" hunks represent text present in current buffer, but not in index.
--- - "Change" hunks represent modified text already present in index.
--- - "Delete" hunks represent text deleted from index.
---
--- Applying hunks means staging, a.k.a adding to index.
--- Notes:
--- - Requires Git version at least 2.38.0.
--- - There is no capability for unstaging hunks. Use full Git client for that.
---
---@return table Source. See |MiniDiff-source-specification|.
MiniDiff.gen_source.git = function()
  local attach = function(buf_id)
    -- Try attaching to a buffer only once
    if H.git_cache[buf_id] ~= nil then return false end

    -- Possibly resolve symlinks to get data from the original repo
    local path = H.get_buf_realpath(buf_id)
    if path == '' then path = vim.api.nvim_buf_get_name(buf_id) end
    if path == '' then return false end

    -- Claim Git cache to not try to attach to the non-Git path several times.
    -- NOTE: Do this after `path==''` check since the same buffer can be reused
    -- for opening actual file (`nvim` -> `:edit file`).
    H.git_cache[buf_id] = require('mini.diff.hunks_cache').git_attachment(buf_id)
    H.git_start_watching_index(buf_id, path)
  end

  local detach = function(buf_id)
    local cache = H.git_cache[buf_id]
    H.git_cache[buf_id] = nil
    local snapshots = require('mini.diff.hunks_cache')
    snapshots.staged.clear(buf_id)
    snapshots.unsaved.clear(buf_id)
    snapshots.untracked.clear(buf_id)
    H.git_invalidate_cache(cache)
  end

  local apply_hunks = function(buf_id, hunks)
    local path_data = H.git_get_path_data(H.get_buf_realpath(buf_id))
    if path_data == nil or path_data.rel_path == nil then return end
    local patch = H.git_format_patch(buf_id, hunks, path_data)
    H.git_apply_patch(path_data, patch)
  end

  -- Ensure to clean source cache for `:edit` to force reattach, since regular
  -- `disable()` from `on_detach` is not enough as there can be no source
  -- attached (like for files not in Git repo).
  local augroup = vim.api.nvim_create_augroup('MiniDiffSourceGit', { clear = true })
  local clear_buf_cache = function(ev)
    H.git_invalidate_cache(H.git_cache[ev.buf])
    H.git_cache[ev.buf] = nil
  end
  local au_opts = { group = augroup, callback = clear_buf_cache, desc = 'Clear Git cache' }
  vim.api.nvim_create_autocmd({ 'BufUnload' }, au_opts)

  return { name = 'git', attach = attach, detach = detach, apply_hunks = apply_hunks }
end

--- "Do nothing" source
---
--- Allows buffers to be enabled while not setting any reference text.
--- Use this if the goal is to rely on manual |MiniDiff.set_ref_text()| calls.
---
---@return table Source. See |MiniDiff-source-specification|.
MiniDiff.gen_source.none = function()
  return { name = 'none', attach = function() end }
end

--- Latest save source
---
--- Uses text at latest save as the reference. This results into diff showing
--- difference after the latest save.
---
---@return table Source. See |MiniDiff-source-specification|.
MiniDiff.gen_source.save = function()
  local augroups = {}
  local attach = function(buf_id)
    local augroup = vim.api.nvim_create_augroup('MiniDiffSourceSaveBuffer' .. buf_id, { clear = true })
    augroups[buf_id] = augroup

    local set_ref = function()
      if vim.bo[buf_id].modified then return end
      MiniDiff.set_ref_text(buf_id, H.get_buftext(buf_id))
    end

    -- Autocommand are more efficient than file watcher as it doesn't read disk
    local au_opts = { group = augroup, buffer = buf_id, callback = set_ref, desc = 'Set reference text after save' }
    vim.api.nvim_create_autocmd({ 'BufWritePost', 'FileChangedShellPost' }, au_opts)
    set_ref()
  end

  local detach = function(buf_id) pcall(vim.api.nvim_del_augroup_by_id, augroups[buf_id]) end

  return { name = 'save', attach = attach, detach = detach }
end

--- Perform action on hunks in region
---
--- Compute hunks inside a target region (even for hunks only partially inside it)
--- and perform apply/reset/yank operation on them.
---
--- The "yank" action yanks all reference lines of target hunks into
--- a specified register (should be one of |registers|).
---
--- Notes:
--- - Whether hunk is inside a region is computed based on position of its
---   buffer lines.
--- - If "change" or "delete" is only partially inside a target region, all
---   reference lines are used in computed "intersection" hunk.
---
--- Used directly in `config.mappings.apply` and `config.mappings.reset`.
--- Usually there is no need to use this function manually.
--- See |MiniDiff.operator()| for how to set up a mapping for "yank".
---
---@param buf_id __diff_buf_id
---@param action string One of "apply", "reset", "yank".
---@param opts table|nil Options. Possible fields:
---   - <line_start> `(number)` - start line of the region. Default: 1.
---   - <line_end> `(number)` - start line of the region. Default: last buffer line.
---   - <register> `(string)` - register to yank reference lines into.
---     Default: |v:register|.
MiniDiff.do_hunks = function(buf_id, action, opts)
  buf_id = H.validate_buf_id(buf_id)
  local buf_cache = H.cache[buf_id]
  if buf_cache == nil then H.error(string.format('Buffer %d is not enabled.', buf_id)) end
  if type(buf_cache.ref_text) ~= 'string' then H.error(string.format('Buffer %d has no reference text.', buf_id)) end

  if not (action == 'apply' or action == 'reset' or action == 'yank') then
    H.error('`action` should be one of "apply", "reset", "yank".')
  end

  local default_opts = { line_start = 1, line_end = vim.api.nvim_buf_line_count(buf_id), register = vim.v.register }
  opts = vim.tbl_deep_extend('force', default_opts, opts or {})
  local line_start, line_end = H.validate_target_lines(buf_id, opts.line_start, opts.line_end)
  if type(opts.register) ~= 'string' then H.error('`opts.register` should be string.') end

  local hunks = H.get_hunks_in_range(buf_cache.hunks, line_start, line_end)
  if #hunks == 0 then return H.notify('No hunks to ' .. action, 'INFO') end
  if action == 'apply' then H.get_active_source(buf_cache).apply_hunks(buf_id, hunks) end
  if action == 'reset' then H.reset_hunks(buf_id, hunks) end
  if action == 'yank' then H.yank_hunks_ref(buf_cache.ref_text, hunks, opts.register) end
end

--- Go to hunk range in current buffer
---
---@param direction string One of "first", "prev", "next", "last".
---@param opts table|nil Options. A table with fields:
---   - <n_times> `(number)` - Number of times to advance. Default: |v:count1|.
---   - <line_start> `(number)` - Line number to start from for directions
---     "prev" and "next". Default: cursor line.
---   - <wrap> `(boolean)` - Whether to wrap around edges.
---     Default: `options.wrap` value of the config.
---   - <staged> `(boolean)` - Include staged display anchors. Default: false.
MiniDiff.goto_hunk = function(direction, opts)
  local buf_id = vim.api.nvim_get_current_buf()
  local buf_cache = H.cache[buf_id]
  if buf_cache == nil then H.error(string.format('Buffer %d is not enabled.', buf_id)) end

  if not vim.tbl_contains({ 'first', 'prev', 'next', 'last' }, direction) then
    H.error('`direction` should be one of "first", "prev", "next", "last".')
  end

  local default_wrap = buf_cache.config.options.wrap_goto
  local default_opts = { n_times = vim.v.count1, line_start = vim.fn.line('.'), wrap = default_wrap }
  opts = vim.tbl_deep_extend('force', default_opts, opts or {})
  if not (type(opts.n_times) == 'number' and opts.n_times >= 1) then
    H.error('`opts.n_times` should be positive number.')
  end
  if type(opts.line_start) ~= 'number' then H.error('`opts.line_start` should be number.') end
  if type(opts.wrap) ~= 'boolean' then H.error('`opts.wrap` should be boolean.') end

  -- Prepare ranges to iterate.
  local ranges = opts.staged and MiniDiff.get_navigation_hunk_ranges(buf_id) or H.get_contiguous_hunk_ranges(buf_cache.hunks)
  return require('mini.diff.navigation.global_navigation').move(ranges, direction, opts, H.notify)
end

--- Perform action over region
---
--- Perform action over region defined by marks. Used in mappings.
---
--- Example of a mapping to yank reference lines of hunk range under cursor
--- (assuming default `config.mappings.textobject`): >lua
---
---   local rhs = function() return MiniDiff.operator('yank') .. 'gh' end
---   vim.keymap.set('n', 'ghy', rhs, { expr = true, remap = true })
--- <
---@param mode string One of "apply", "reset", "yank", or the ones used in |g@|.
MiniDiff.operator = function(mode)
  local buf_id = vim.api.nvim_get_current_buf()
  if H.is_disabled(buf_id) then return '' end

  if mode == 'apply' or mode == 'reset' or mode == 'yank' then
    H.operator_cache = { action = mode, win_view = vim.fn.winsaveview(), register = vim.v.register }
    vim.o.operatorfunc = 'v:lua.MiniDiff.operator'
    return 'g@'
  end
  local cache = H.operator_cache

  -- NOTE: Using `[` / `]` marks also works in Visual mode as because it is
  -- executed as part of `g@`, which treats visual selection as a result of
  -- Operator-pending mode mechanics (for which visual selection is allowed to
  -- define motion/textobject). The downside is that it sets 'operatorfunc',
  -- but the upside is that it is "dot-repeatable" (for relative selection).
  local opts = { line_start = vim.fn.line("'["), line_end = vim.fn.line("']"), register = cache.register }
  if opts.line_end < opts.line_start then return H.notify('Not a proper textobject', 'INFO') end
  MiniDiff.do_hunks(buf_id, cache.action, opts)

  -- Restore window view for "apply" (as buffer text should not have changed)
  if cache.action == 'apply' and cache.win_view ~= nil then
    vim.fn.winrestview(cache.win_view)
    -- NOTE: Restore only once because during dot-repeat it is not up to date
    cache.win_view = nil
  end
  return ''
end

--- Select hunk range textobject
---
--- Selects all contiguous lines adjacent to cursor line which are in any (not
--- necessarily same) hunk (if cursor line itself is in hunk).
--- Used in default mappings.
MiniDiff.textobject = function()
  local buf_id = vim.api.nvim_get_current_buf()
  local buf_cache = H.cache[buf_id]
  if buf_cache == nil or H.is_disabled(buf_id) then H.error('Current buffer is not enabled.') end

  -- Get hunk range under cursor
  local cur_line = vim.fn.line('.')
  local regions, cur_region = H.get_contiguous_hunk_ranges(buf_cache.hunks), nil
  for _, r in ipairs(regions) do
    if r.from <= cur_line and cur_line <= r.to then cur_region = r end
  end
  if cur_region == nil then return H.notify('No hunk range under cursor', 'INFO') end

  -- Select target region
  local is_visual = vim.tbl_contains({ 'v', 'V', '\22' }, vim.fn.mode())
  if is_visual then vim.cmd('normal! \27') end
  vim.cmd(string.format('normal! %dGV%dG', cur_region.from, cur_region.to))
end

--- Indicate source attach fail
---
--- Try to attach next source; if there is none - call |MiniDiff.disable()|.
---
---@param buf_id integer Buffer identifier for which attach has failed.
MiniDiff.fail_attach = function(buf_id)
  buf_id = H.validate_buf_id(buf_id)

  -- Do nothing if there was no attempt to enable
  local buf_cache = H.cache[buf_id]
  if buf_cache == nil then return end

  -- If no next source, disable buffer without calling any of `detach`
  if buf_cache.source_id >= #buf_cache.source then
    H.cache[buf_id].source_id = math.huge
    return MiniDiff.disable(buf_id)
  end

  -- Try attaching next source
  pcall(H.get_active_source(buf_cache).detach, buf_id)
  buf_cache.ref_pending = nil
  buf_cache.ref_error = nil
  buf_cache.ref_text = nil
  buf_cache.has_result = nil
  H.set_state(buf_id, 'unavailable', 'No reference text available')
  buf_cache.source_id = buf_cache.source_id + 1
  local attach_output = H.get_active_source(H.cache[buf_id]).attach(buf_id)
  if attach_output == false then MiniDiff.fail_attach(buf_id) end
end

-- Helper data ================================================================
-- Module default config
H.default_config = MiniDiff.config

H.default_source = { MiniDiff.gen_source.git() }

-- Timers
H.timer_diff_update = vim.loop.new_timer()

-- Namespaces per highlighter name
H.ns_id = require('mini.diff.rendering').namespaces

-- Cache of buffers waiting for debounced diff update
H.bufs_to_update = {}

-- Cache per enabled buffer
H.cache = {}

-- Small lifecycle snapshots, separate from the potentially large hunk cache.
H.states = require('mini.diff.hunks_cache').states_adapter()

-- Cache per buffer for attached `git` source
H.git_cache = {}

-- Cache for operator
H.operator_cache = {}

-- Common extmark data for supported styles
--stylua: ignore
H.style_extmark_data = {
  sign    = { hl_group_prefix = 'MiniDiffSign', field = 'sign_hl_group' },
  number  = { hl_group_prefix = 'MiniDiffSign', field = 'number_hl_group' },
}

-- Suffix for overlay virtual lines to be highlighted as full line
H.overlay_suffix = string.rep(' ', vim.o.columns)

-- Flag for whether to handle virtual lines overflow
H.extmark_virt_lines_overflow = vim.fn.has('nvim-0.11') == 1 and 'scroll' or nil

-- Permanent `vim.diff()` options
H.vimdiff_opts = { result_type = 'indices', ctxlen = 0, interhunkctxlen = 0 }

-- Options for `vim.diff()` during word diff. Use `interhunkctxlen = 4` to
-- reduce noisiness (chosen as slightly less than average English word length)
--stylua: ignore
H.worddiff_opts = {
  algorithm = 'minimal',    result_type = 'indices',
  ctxlen = 0,               interhunkctxlen = 4,
  indent_heuristic = false, linematch = 0
}

-- BOM bytes prepended to buffer text if 'bomb' is enabled. See `:h bom-bytes`.
--stylua: ignore
H.bom_bytes = {
  ['utf-8']    = string.char(0xef, 0xbb, 0xbf),
  ['utf-16be'] = string.char(0xfe, 0xff),
  ['utf-16']   = string.char(0xfe, 0xff),
  ['utf-16le'] = string.char(0xff, 0xfe),
  -- In 'fileencoding', 'utf-32' is transformed into 'ucs-4'
  ['utf-32be'] = string.char(0x00, 0x00, 0xfe, 0xff),
  ['ucs-4be']  = string.char(0x00, 0x00, 0xfe, 0xff),
  ['utf-32']   = string.char(0x00, 0x00, 0xfe, 0xff),
  ['ucs-4']    = string.char(0x00, 0x00, 0xfe, 0xff),
  ['utf-32le'] = string.char(0xff, 0xfe, 0x00, 0x00),
  ['ucs-4le']  = string.char(0xff, 0xfe, 0x00, 0x00),
}

-- Helper functionality =======================================================
-- Settings -------------------------------------------------------------------
H.setup_config = function(config)
  H.check_type('config', config, 'table', true)
  config = vim.tbl_deep_extend('force', vim.deepcopy(H.default_config), config or {})

  H.check_type('view', config.view, 'table')
  H.check_type('view.style', config.view.style, 'string')
  H.check_type('view.signs', config.view.signs, 'table')
  H.check_type('view.signs.add', config.view.signs.add, 'string')
  H.check_type('view.signs.change', config.view.signs.change, 'string')
  H.check_type('view.signs.delete', config.view.signs.delete, 'string')
  H.check_type('view.priority', config.view.priority, 'number')

  H.check_type('source', config.source, 'table', true)

  H.check_type('delay', config.delay, 'table')
  H.check_type('delay.text_change', config.delay.text_change, 'number')

  H.check_type('mappings', config.mappings, 'table')
  H.check_type('mappings.apply', config.mappings.apply, 'string')
  H.check_type('mappings.reset', config.mappings.reset, 'string')
  H.check_type('mappings.textobject', config.mappings.textobject, 'string')
  H.check_type('mappings.goto_first', config.mappings.goto_first, 'string')
  H.check_type('mappings.goto_prev', config.mappings.goto_prev, 'string')
  H.check_type('mappings.goto_next', config.mappings.goto_next, 'string')
  H.check_type('mappings.goto_last', config.mappings.goto_last, 'string')

  H.check_type('options', config.options, 'table')
  H.check_type('options.algorithm', config.options.algorithm, 'string')
  H.check_type('options.indent_heuristic', config.options.indent_heuristic, 'boolean')
  H.check_type('options.linematch', config.options.linematch, 'number')
  H.check_type('options.wrap_goto', config.options.wrap_goto, 'boolean')

  return config
end

H.apply_config = function(config)
  MiniDiff.config = config

  -- Make mappings
  local mappings = config.mappings

  local rhs_apply = function() return MiniDiff.operator('apply') end
  H.map({ 'n', 'x' }, mappings.apply, rhs_apply, { expr = true, desc = 'Apply hunks' })
  local rhs_reset = function() return MiniDiff.operator('reset') end
  H.map({ 'n', 'x' }, mappings.reset, rhs_reset, { expr = true, desc = 'Reset hunks' })

  local is_tobj_conflict = mappings.textobject == mappings.apply or mappings.textobject == mappings.reset
  local modes = is_tobj_conflict and { 'o' } or { 'x', 'o' }
  H.map(modes, mappings.textobject, '<Cmd>lua MiniDiff.textobject()<CR>', { desc = 'Hunk range textobject' })

  --stylua: ignore start
  H.map({ 'n', 'x' }, mappings.goto_first,  "<Cmd>lua MiniDiff.goto_hunk('first')<CR>", { desc = 'First hunk' })
  H.map('o',          mappings.goto_first, "V<Cmd>lua MiniDiff.goto_hunk('first')<CR>", { desc = 'First hunk' })
  H.map({ 'n', 'x' }, mappings.goto_prev,   "<Cmd>lua MiniDiff.goto_hunk('prev')<CR>",  { desc = 'Previous hunk' })
  H.map('o',          mappings.goto_prev,  "V<Cmd>lua MiniDiff.goto_hunk('prev')<CR>",  { desc = 'Previous hunk' })
  H.map({ 'n', 'x' }, mappings.goto_next,   "<Cmd>lua MiniDiff.goto_hunk('next')<CR>",  { desc = 'Next hunk' })
  H.map('o',          mappings.goto_next,  "V<Cmd>lua MiniDiff.goto_hunk('next')<CR>",  { desc = 'Next hunk' })
  H.map({ 'n', 'x' }, mappings.goto_last,   "<Cmd>lua MiniDiff.goto_hunk('last')<CR>",  { desc = 'Last hunk' })
  H.map('o',          mappings.goto_last,  "V<Cmd>lua MiniDiff.goto_hunk('last')<CR>",  { desc = 'Last hunk' })
  --stylua: ignore end

  -- Register decoration provider which actually makes visualization
  local ns_id_viz, ns_id_overlay = H.ns_id.viz, H.ns_id.overlay
  H.set_decoration_provider(ns_id_viz, ns_id_overlay)
end

H.create_autocommands = function()
  local gr = vim.api.nvim_create_augroup('MiniDiff', {})

  local au = function(event, pattern, callback, desc)
    vim.api.nvim_create_autocmd(event, { group = gr, pattern = pattern, callback = callback, desc = desc })
  end

  -- NOTE: Try auto enabling buffer on every `BufEnter` to not have `:edit`
  -- disabling buffer, as it calls `on_detach()` from buffer watcher
  au('BufEnter', '*', H.auto_enable, 'Enable diff')
  au('FocusGained', '*', function(ev)
    if H.git_cache[ev.buf] then H.git_set_ref_text(ev.buf) end
  end, 'Revalidate Git snapshots')
  au('BufWipeout', '*', function(ev)
    if H.cache[ev.buf] then MiniDiff.disable(ev.buf) end
    H.states[ev.buf] = nil
  end, 'Clear diff lifecycle')
  au('VimResized', '*', H.on_resize, 'Track Neovim resizing')
  au('ColorScheme', '*', H.create_default_hl, 'Ensure colors')
end

--stylua: ignore
H.create_default_hl = function()
  local hi = function(name, opts)
    opts.default = true
    vim.api.nvim_set_hl(0, name, opts)
  end

  hi('MiniDiffSignAdd',        { link = 'Added' })
  hi('MiniDiffSignChange',     { link = 'Changed' })
  hi('MiniDiffSignDelete',     { link = 'Removed' })
  hi('MiniDiffSignStagedAdd',    { link = 'MiniDiffSignAdd' })
  hi('MiniDiffSignStagedChange', { link = 'MiniDiffSignChange' })
  hi('MiniDiffSignStagedDelete', { link = 'MiniDiffSignDelete' })
  hi('MiniDiffSignMixed',        { link = 'MiniDiffSignChange' })
  hi('MiniDiffOverAdd',        { link = 'DiffAdd' })
  hi('MiniDiffOverChange',     { link = 'DiffText' })
  hi('MiniDiffOverChangeBuf',  { link = 'MiniDiffOverChange'})
  hi('MiniDiffOverContext',    { link = 'DiffChange' })
  hi('MiniDiffOverContextBuf', {})
  hi('MiniDiffOverDelete',     { link = 'DiffDelete'  })
end

H.is_disabled = function(buf_id)
  local buf_disable = H.get_buf_var(buf_id, 'minidiff_disable')
  return vim.g.minidiff_disable == true or buf_disable == true
end

H.get_config = function(config, buf_id)
  local buf_config = H.get_buf_var(buf_id, 'minidiff_config') or {}
  return vim.tbl_deep_extend('force', MiniDiff.config, buf_config, config or {})
end

H.get_buf_var = function(buf_id, name)
  if not vim.api.nvim_buf_is_valid(buf_id) then return nil end
  return vim.b[buf_id or 0][name]
end

-- Autocommands ---------------------------------------------------------------
H.auto_enable = vim.schedule_wrap(function(data)
  if H.is_buf_enabled(data.buf) or H.is_disabled(data.buf) then return end
  local buf = data.buf
  if not (vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == '' and vim.bo[buf].buflisted) then return end
  if not H.is_buf_text(buf) then return end
  MiniDiff.enable(buf)
end)

H.on_resize = function()
  H.overlay_suffix = string.rep(' ', vim.o.columns)
  for buf_id, _ in pairs(H.cache) do
    if vim.api.nvim_buf_is_valid(buf_id) then
      H.clear_all_diff(buf_id)
      H.schedule_diff_update(buf_id, 0)
    end
  end
end

-- Validators -----------------------------------------------------------------
H.validate_buf_id = function(x)
  if x == nil or x == 0 then return vim.api.nvim_get_current_buf() end
  if not (type(x) == 'number' and vim.api.nvim_buf_is_valid(x)) then
    H.error('`buf_id` should be `nil` or valid buffer id.')
  end
  return x
end

H.validate_target_lines = function(buf_id, line_start, line_end)
  local n_lines = vim.api.nvim_buf_line_count(buf_id)

  if type(line_start) ~= 'number' then H.error('`line_start` should be number.') end
  if type(line_end) ~= 'number' then H.error('`line_end` should be number.') end

  -- Allow negative lines to count from last line
  line_start = line_start < 0 and (n_lines + line_start + 1) or line_start
  line_end = line_end < 0 and (n_lines + line_end + 1) or line_end

  -- Clamp to fit the allowed range
  line_start = math.min(math.max(line_start, 1), n_lines)
  line_end = math.min(math.max(line_end, 1), n_lines)
  if not (line_start <= line_end) then H.error('`line_start` should be less than or equal to `line_end`.') end

  return line_start, line_end
end

H.validate_callable = function(x, name)
  if vim.is_callable(x) then return x end
  H.error('`' .. name .. '` should be callable.')
end

-- Enabling -------------------------------------------------------------------
H.is_buf_enabled = function(buf_id) return H.cache[buf_id] ~= nil end

H.set_state = function(buf_id, status, reason)
  local previous = H.states[buf_id]
  if previous and previous.status == status and previous.reason == reason then return end
  H.states[buf_id] = { status = status, reason = reason }
  if not vim.api.nvim_buf_is_valid(buf_id) then return end
  vim.api.nvim_exec_autocmds('User', { pattern = 'MiniDiffStateChanged', data = { buf = buf_id } })
end

H.pending_state = function(buf_id)
  local cache = H.cache[buf_id]
  if cache == nil then return end
  H.set_state(buf_id, cache.has_result and 'updating' or 'loading')
end

H.update_buf_cache = function(buf_id)
  local new_cache = require('mini.diff.hunks_cache').attachment(buf_id, H.cache[buf_id])

  local buf_config = H.get_config({}, buf_id)
  new_cache.config = buf_config
  new_cache.extmark_opts = H.convert_view_to_extmark_opts(buf_config.view)
  new_cache.source = H.normalize_source(buf_config.source or H.default_source)
  new_cache.source_id = new_cache.source_id or 1

  new_cache.hunks = new_cache.hunks or {}
  new_cache.summary = new_cache.summary or {}
  new_cache.viz_lines = new_cache.viz_lines or {}

  if new_cache.overlay == nil then new_cache.overlay = false end
  new_cache.overlay_lines = new_cache.overlay_lines or {}

  H.cache[buf_id] = new_cache
end

H.setup_buf_autocommands = function(buf_id)
  local augroup = vim.api.nvim_create_augroup('MiniDiffBuffer' .. buf_id, { clear = true })
  H.cache[buf_id].augroup = augroup

  local buf_update = vim.schedule_wrap(function()
    if H.cache[buf_id] ~= nil then H.update_buf_cache(buf_id) end
  end)
  local bufwinenter_opts = { group = augroup, buffer = buf_id, callback = buf_update, desc = 'Update buffer cache' }
  vim.api.nvim_create_autocmd('BufWinEnter', bufwinenter_opts)
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = augroup, buffer = buf_id, desc = 'Refresh saved hunk baseline',
    callback = function() if H.cache[buf_id] then H.schedule_diff_update(buf_id, 0) end end,
  })

  local reset_if_enabled = vim.schedule_wrap(function(data)
    if not H.is_buf_enabled(data.buf) then return end
    MiniDiff.disable(data.buf)
    MiniDiff.enable(data.buf)
  end)
  local bufrename_opts = { group = augroup, buffer = buf_id, callback = reset_if_enabled, desc = 'Reset on rename' }
  -- NOTE: `BufFilePost` does not look like a proper event, but it (yet) works
  vim.api.nvim_create_autocmd('BufFilePost', bufrename_opts)

  local buf_disable = function() MiniDiff.disable(buf_id) end
  local bufdelete_opts = { group = augroup, buffer = buf_id, callback = buf_disable, desc = 'Disable on delete' }
  vim.api.nvim_create_autocmd('BufDelete', bufdelete_opts)
end

H.normalize_source = function(source)
  -- Normalize to an array of sources
  if type(source) ~= 'table' then H.error('`source` should be table.') end
  if source[1] == nil then source = { source } end

  local res = {}
  for i, s in ipairs(source) do
    local cur_s = { attach = s.attach }
    cur_s.name = s.name or 'unknown'
    cur_s.detach = s.detach or function(_) end
    cur_s.apply_hunks = s.apply_hunks or function(_) H.error('Current source does not support applying hunks.') end

    if type(cur_s.name) ~= 'string' then H.error('`source.name` should be string.') end
    H.validate_callable(cur_s.attach, 'source.attach')
    H.validate_callable(cur_s.detach, 'source.detach')
    H.validate_callable(cur_s.apply_hunks, 'source.apply_hunks')

    res[i] = cur_s
  end

  return res
end

H.get_active_source = function(buf_cache) return buf_cache.source[buf_cache.source_id] or {} end

H.convert_view_to_extmark_opts = function(view)
  local extmark_data = H.style_extmark_data[view.style]
  if extmark_data == nil then H.error('Style ' .. vim.inspect(view.style) .. ' is not supported.') end

  local signs = view.style == 'sign' and view.signs or {}
  local field, hl_group_prefix = extmark_data.field, extmark_data.hl_group_prefix
  --stylua: ignore
  return {
    add =    { [field] = hl_group_prefix .. 'Add',    sign_text = signs.add,    priority = view.priority, invalidate = true },
    change = { [field] = hl_group_prefix .. 'Change', sign_text = signs.change, priority = view.priority, invalidate = true },
    delete = { [field] = hl_group_prefix .. 'Delete', sign_text = signs.delete, priority = view.priority, invalidate = true },
  }
end

-- Processing -----------------------------------------------------------------
H.schedule_diff_update = function(buf_id, delay_ms)
  local cache = H.cache[buf_id]
  if cache == nil then return end
  H.pending_state(buf_id)
  H.queue_diff_update(buf_id, delay_ms, cache)
end

H.queue_diff_update = vim.schedule_wrap(function(buf_id, delay_ms, cache)
  if H.cache[buf_id] ~= cache then return end
  H.bufs_to_update[buf_id] = cache
  H.timer_diff_update:stop()
  H.timer_diff_update:start(delay_ms, 0, H.process_scheduled_buffers)
end)

H.process_scheduled_buffers = vim.schedule_wrap(function()
  for buf_id, cache in pairs(H.bufs_to_update) do
    H.update_buf_diff(buf_id, cache)
  end
  H.bufs_to_update = {}
end)

H.update_buf_diff_now = function(buf_id, expected_cache)
  -- Make early returns
  local buf_cache = H.cache[buf_id]
  if buf_cache == nil or buf_cache ~= expected_cache then return end
  if not vim.api.nvim_buf_is_valid(buf_id) then
    H.cache[buf_id] = nil
    return
  end
  if type(buf_cache.ref_text) ~= 'string' or H.is_disabled(buf_id) then
    local summary = { source_name = H.get_active_source(buf_cache).name }
    buf_cache.hunks, buf_cache.viz_lines, buf_cache.overlay_lines, buf_cache.summary = {}, {}, {}, summary
    vim.b[buf_id].minidiff_summary, vim.b[buf_id].minidiff_summary_string = summary, ''
    if not buf_cache.ref_pending then
      H.set_state(buf_id, buf_cache.ref_error and 'failed' or 'unavailable', buf_cache.ref_error or 'No reference text available')
    end
    return
  end

  -- Compute diff
  local options = buf_cache.config.options
  H.vimdiff_opts.algorithm = options.algorithm
  H.vimdiff_opts.indent_heuristic = options.indent_heuristic
  H.vimdiff_opts.linematch = options.linematch

  local buf_text, buf_lines = H.get_buftext(buf_id)
  local ok, result = pcall(require('mini.diff.hunks_loader.unstaged').compute, buf_cache.ref_text, buf_text, H.vimdiff_opts)
  if not ok then
    H.set_state(buf_id, 'failed', tostring(result))
    return
  end

  -- Recompute hunks with summary and draw information
  buf_cache.hunks, buf_cache.summary = result.hunks, result.summary
  buf_cache.summary.source_name = H.get_active_source(buf_cache).name
  if H.get_active_source(buf_cache).name == 'git' then require('mini.diff.hunks_loader').capture(buf_id, buf_text, H.vimdiff_opts) end
  H.update_hunk_data(result.indices, buf_cache, buf_lines)
  if H.git_cache[buf_id] then require('mini.diff.navigation.staged').update(buf_id, buf_cache.hunks, #buf_lines, H.git_cache[buf_id]) end
  H.update_staged_viz(buf_id, buf_cache, #buf_lines)
  buf_cache.has_result = true

  -- Set buffer-local variables with summary for easier external usage
  local summary = buf_cache.summary
  vim.b[buf_id].minidiff_summary = summary

  local summary_string = {}
  if summary.n_ranges > 0 then table.insert(summary_string, '#' .. summary.n_ranges) end
  if summary.add > 0 then table.insert(summary_string, '+' .. summary.add) end
  if summary.change > 0 then table.insert(summary_string, '~' .. summary.change) end
  if summary.delete > 0 then table.insert(summary_string, '-' .. summary.delete) end
  vim.b[buf_id].minidiff_summary_string = table.concat(summary_string, ' ')
  if not buf_cache.ref_pending then
    H.set_state(buf_id, buf_cache.ref_error and 'failed' or 'ready', buf_cache.ref_error)
  end

  -- Request highlighting clear to be done in decoration provider
  buf_cache.needs_clear = true

  -- Trigger event for users to possibly hook into. Ensure target buffer is
  -- current (for proper `buf` in event data)
  vim.api.nvim_buf_call(buf_id, function() vim.api.nvim_exec_autocmds('User', { pattern = 'MiniDiffUpdated' }) end)

  -- Force redraw. NOTE: Using 'redraw' not always works (`<Cmd>update<CR>`
  -- from keymap with "save" source will not redraw) while 'redraw!' flickers.
  H.redraw_buffer(buf_id)
end

H.update_buf_diff = vim.schedule_wrap(H.update_buf_diff_now)

-- Hunks ----------------------------------------------------------------------
H.get_hunk_buf_range = function(hunk)
  -- "Change" and "Add" hunks have the range `[from, from + buf_count - 1]`
  if hunk.buf_count > 0 then return hunk.buf_start, hunk.buf_start + hunk.buf_count - 1 end
  -- "Delete" hunks have `buf_count = 0` yet its range is `[from, from]`
  -- `buf_start` can be 0 for 'delete' hunk, yet range should be real lines
  local from = math.max(hunk.buf_start, 1)
  return from, from
end

H.get_hunks_in_range = function(hunks, from, to)
  local res = {}
  for _, h in ipairs(hunks) do
    local h_from, h_to = H.get_hunk_buf_range(h)

    local left, right = math.max(from, h_from), math.min(to, h_to)
    if left <= right then
      -- If any `cur` hunk part is selected, its `ref` part is used fully
      local new_h = { ref_start = h.ref_start, ref_count = h.ref_count }
      new_h.type = h.ref_count == 0 and 'add' or (h.buf_count == 0 and 'delete' or 'change')

      -- It should be possible to work with only hunk part inside target range
      -- Also Treat "delete" hunks differently as they represent range differently
      -- and can have `buf_start=0`
      new_h.buf_start = new_h.type == 'delete' and h.buf_start or left
      new_h.buf_count = new_h.type == 'delete' and 0 or (right - left + 1)

      table.insert(res, new_h)
    end
  end

  table.sort(res, H.hunk_order)
  return res
end

H.reset_hunks = function(buf_id, hunks)
  local ref_lines = vim.split(H.cache[buf_id].ref_text, '\n')
  local offset = 0
  for _, h in ipairs(hunks) do
    -- Replace current hunk lines with corresponding reference
    local new_lines = vim.list_slice(ref_lines, h.ref_start, h.ref_start + h.ref_count - 1)

    -- Compute buffer offset from parts: result of previous replaces, "delete"
    -- hunk offset which starts below the `buf_start` line, zero-indexing.
    local buf_offset = offset + (h.buf_count == 0 and 1 or 0) - 1
    local from, to = h.buf_start + buf_offset, h.buf_start + h.buf_count + buf_offset
    vim.api.nvim_buf_set_lines(buf_id, from, to, false, new_lines)

    -- Keep track of current hunk lines shift as a result of previous replaces
    offset = offset + (h.ref_count - h.buf_count)
  end
end

H.yank_hunks_ref = function(ref_text, hunks, register)
  -- Collect reference lines
  local ref_lines, out_lines = vim.split(ref_text, '\n'), {}
  for _, h in ipairs(hunks) do
    for i = h.ref_start, h.ref_start + h.ref_count - 1 do
      out_lines[i] = ref_lines[i]
    end
  end

  -- Construct reference lines in order
  local hunk_ref_lines = {}
  for i = 1, #ref_lines do
    table.insert(hunk_ref_lines, out_lines[i])
  end

  -- Put lines into target register
  vim.fn.setreg(register, hunk_ref_lines, 'l')
end

H.get_contiguous_hunk_ranges = require('mini.diff.navigation.global_navigation').contiguous

H.hunk_order = function(a, b)
  -- Ensure buffer order and that "change" hunks are listed earlier "delete"
  -- ones from the same line (important for `reset_hunks()`)
  return a.buf_start < b.buf_start or (a.buf_start == b.buf_start and a.type == 'change' and b.type ~= 'change')
end

-- Export ---------------------------------------------------------------------
H.export_qf = function(opts)
  local buffers = opts.scope == 'current' and { vim.api.nvim_get_current_buf() } or vim.tbl_keys(H.cache)
  buffers = vim.tbl_filter(vim.api.nvim_buf_is_valid, buffers)
  table.sort(buffers)

  local type_text = { add = 'Add', change = 'Change', delete = 'Delete' }

  local res = {}
  for _, buf_id in ipairs(buffers) do
    local filename = vim.api.nvim_buf_get_name(buf_id)
    local buf_lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
    for _, h in ipairs(H.cache[buf_id].hunks) do
      local text = type_text[h.type]
      local entry = { bufnr = buf_id, filename = filename, type = text:sub(1, 1), text = text }
      entry.lnum, entry.end_lnum = H.get_hunk_buf_range(h)
      -- Make 'add' and 'change' hunks represent actual buffer regions
      entry.col, entry.end_col = 1, h.type == 'delete' and 1 or buf_lines[entry.end_lnum]:len() + 1
      table.insert(res, entry)
    end
  end
  return res
end

-- Git ------------------------------------------------------------------------
H.git_start_watching_index = function(buf_id, path)
  -- NOTE: Watching single 'index' file is not enough as staging by Git is done
  -- via "create fresh 'index.lock' file, apply modifications, change file name
  -- to 'index'". Hence watch the whole '.git' (first level) and react only if
  -- change was in 'index' file.
  local args = { 'rev-parse', '--path-format=absolute', '--git-dir' }
  local cache, git_cache = H.cache[buf_id], H.git_cache[buf_id]
  cache.ref_pending = true
  cache.ref_error = nil
  H.pending_state(buf_id)
  H.git_read_reference(args, vim.fn.fnamemodify(path, ':h'), function(code, text, err)
    if H.cache[buf_id] ~= cache or H.git_cache[buf_id] ~= git_cache then return end
    cache.ref_pending = nil
    cache.ref_error = err
    if err then return H.set_state(buf_id, 'failed', err) end
    if code ~= 0 or text == '' then return MiniDiff.fail_attach(buf_id) end
    H.git_setup_index_watch(buf_id, text:gsub('\n+$', ''))
    H.git_set_ref_text(buf_id)
  end)
end

H.git_setup_index_watch = function(buf_id, git_dir_path)
  local buf_fs_event, timer = vim.loop.new_fs_event(), vim.loop.new_timer()
  local cache = H.git_cache[buf_id]
  local buf_git_set_ref_text = function()
    if H.git_cache[buf_id] == cache then H.git_set_ref_text(buf_id) end
  end

  local watch_index = function(_, filename, _)
    if filename ~= 'index' and filename ~= 'HEAD' and filename ~= 'packed-refs' and filename ~= 'logs' then return end
    -- Debounce to not overload during incremental staging (like in script)
    timer:stop()
    timer:start(50, 0, buf_git_set_ref_text)
  end
  buf_fs_event:start(git_dir_path, { recursive = false }, watch_index)

  cache.fs_event, cache.timer = buf_fs_event, timer
  -- HEAD's reflog changes on commits and branch switches, including worktrees.
  -- It may not exist before the first commit; retry when Git creates `logs`.
  cache.watch_logs = function()
    if cache.logs_event then return end
    local event = vim.loop.new_fs_event()
    local ok = event:start(git_dir_path .. '/logs', {}, watch_index)
    if ok then cache.logs_event = event else event:close() end
  end
  cache.watch_logs()
  -- Watch the symbolic HEAD target as well: reflogs may be disabled, and in
  -- linked worktrees branch refs live in the common Git directory.
  local common_dir = git_dir_path
  local ok, lines = pcall(vim.fn.readfile, git_dir_path .. '/commondir')
  if ok and lines[1] then
    common_dir = lines[1]:sub(1, 1) == '/' and lines[1] or (git_dir_path .. '/' .. lines[1])
    local event = vim.loop.new_fs_event()
    if event:start(common_dir, {}, watch_index) then cache.common_event = event else event:close() end
  end
  cache.watch_ref = function()
    local read_ok, head = pcall(vim.fn.readfile, git_dir_path .. '/HEAD')
    local ref = read_ok and head[1] and head[1]:match('^ref: (refs/.+)$') or nil
    local target = ref and (common_dir .. '/' .. ref) or nil
    if target == cache.ref_path and cache.ref_event then return end
    if cache.ref_event then cache.ref_event:close(); cache.ref_event = nil end
    cache.ref_path = target
    if not target then return end
    local event = vim.loop.new_fs_event()
    local basename = vim.fn.fnamemodify(target, ':t')
    local started = event:start(vim.fn.fnamemodify(target, ':h'), {}, function(_, filename)
      if filename ~= basename then return end
      timer:stop()
      timer:start(50, 0, buf_git_set_ref_text)
    end)
    if started then cache.ref_event = event else event:close() end
  end
  cache.watch_ref()
end

H.git_set_ref_text = function(buf_id)
  return require('mini.diff.hunks_loader').refresh(buf_id, H, MiniDiff)
end

-- Reference reads settle only after both exit and EOF (including empty files).
H.git_read_reference = function(args, cwd, callback)
  local stdout, chunks = vim.loop.new_pipe(), {}
  local process, code, eof, read_error
  local finish = function()
    if code == nil or not eof then return end
    vim.schedule(function() callback(code, table.concat(chunks), read_error) end)
  end
  local err
  process, err = vim.loop.spawn('git', { args = args, cwd = cwd, stdio = { nil, stdout, nil } }, function(exit_code)
    process:close()
    code = exit_code
    finish()
  end)
  if process == nil then
    stdout:close()
    return vim.schedule(function() callback(1, '', 'Could not start Git: ' .. tostring(err)) end)
  end
  stdout:read_start(function(stream_error, data)
    if data then chunks[#chunks + 1] = data end
    if data ~= nil and stream_error == nil then return end
    read_error, eof = stream_error, true
    stdout:close()
    finish()
  end)
end

H.git_get_path_data = function(path)
  -- Get path data needed for proper patch header
  local cwd, basename = vim.fn.fnamemodify(path, ':h'), vim.fn.fnamemodify(path, ':t')
  local stdout = vim.loop.new_pipe()
  local args = { 'ls-files', '-z', '--full-name', '--format=%(objectmode) %(eolinfo:index) %(path)', '--', basename }
  local spawn_opts = { args = args, cwd = cwd, stdio = { nil, stdout, nil } }

  local process, stdout_feed, res, did_exit = nil, {}, { cwd = cwd }, false
  local on_exit = function(exit_code)
    process:close()

    did_exit = true
    if exit_code ~= 0 then return end
    -- Parse data about path
    local out = table.concat(stdout_feed, ''):gsub('(%z\n)+$', '')
    res.mode_bits, res.eol, res.rel_path = string.match(out, '^(%d+) (%S+) (.*)$')
  end

  process = vim.loop.spawn('git', spawn_opts, on_exit)
  H.git_read_stream(stdout, stdout_feed)
  vim.wait(1000, function() return did_exit end, 1)
  return res
end

H.git_format_patch = function(buf_id, hunks, path_data)
  local _, buf_lines = H.get_buftext(buf_id)
  local ref_lines = vim.split(H.cache[buf_id].ref_text, '\n')

  local res = {
    string.format('diff --git a/%s b/%s', path_data.rel_path, path_data.rel_path),
    'index 000000..000000 ' .. path_data.mode_bits,
    '--- a/' .. path_data.rel_path,
    '+++ b/' .. path_data.rel_path,
  }

  -- Take into account changing target ref region as a result of previous hunks
  local offset = 0
  local cr_eol = path_data.eol == 'crlf' and '\r' or ''
  for _, h in ipairs(hunks) do
    -- "Add" hunks have reference line above target
    local start = h.ref_start + (h.ref_count == 0 and 1 or 0)

    table.insert(res, string.format('@@ -%d,%d +%d,%d @@', start, h.ref_count, start + offset, h.buf_count))
    for i = h.ref_start, h.ref_start + h.ref_count - 1 do
      table.insert(res, '-' .. ref_lines[i] .. cr_eol)
    end
    for i = h.buf_start, h.buf_start + h.buf_count - 1 do
      table.insert(res, '+' .. buf_lines[i] .. cr_eol)
    end
    offset = offset + (h.buf_count - h.ref_count)
  end

  return res
end

H.git_apply_patch = function(path_data, patch)
  local stdin = vim.loop.new_pipe()
  local args = { 'apply', '--whitespace=nowarn', '--cached', '--unidiff-zero', '-' }
  local spawn_opts = { args = args, cwd = path_data.cwd, stdio = { stdin, nil, nil } }
  local process
  process = vim.loop.spawn('git', spawn_opts, function() process:close() end)

  -- Write patch, notify that writing is finished (shutdown), and close
  for _, l in ipairs(patch) do
    stdin:write(l)
    stdin:write('\n')
  end
  stdin:shutdown(function() stdin:close() end)
end

H.git_read_stream = function(stream, feed)
  local callback = function(err, data)
    if data ~= nil then return table.insert(feed, data) end
    if err then feed[1] = nil end
    stream:close()
  end
  stream:read_start(callback)
end

H.git_invalidate_cache = function(cache)
  if cache == nil then return end
  pcall(vim.loop.fs_event_stop, cache.fs_event)
  pcall(vim.loop.timer_stop, cache.timer)
  for _, handle in pairs({ cache.fs_event, cache.timer, cache.logs_event, cache.ref_event, cache.common_event }) do
    if not handle:is_closing() then handle:close() end
  end
end

-- Utilities ------------------------------------------------------------------
H.error = function(msg) error('(mini.diff) ' .. msg, 0) end

H.check_type = function(name, val, ref, allow_nil)
  if type(val) == ref or (ref == 'callable' and vim.is_callable(val)) or (allow_nil and val == nil) then return end
  H.error(string.format('`%s` should be %s, not %s', name, ref, type(val)))
end

H.notify = function(msg, level_name) vim.notify('(mini.diff) ' .. msg, vim.log.levels[level_name]) end

H.buf_ensure_loaded = function(buf_id)
  if type(buf_id) ~= 'number' or vim.api.nvim_buf_is_loaded(buf_id) then return end
  local cache_eventignore = vim.o.eventignore
  vim.o.eventignore = 'BufEnter,BufWinEnter'
  pcall(vim.fn.bufload, buf_id)
  vim.o.eventignore = cache_eventignore
end

H.map = function(mode, lhs, rhs, opts)
  if lhs == '' then return end
  opts = vim.tbl_deep_extend('force', { silent = true }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

H.set_extmark = function(...) pcall(vim.api.nvim_buf_set_extmark, ...) end

H.get_extmarks = function(...)
  local ok, res = pcall(vim.api.nvim_buf_get_extmarks, ...)
  if not ok then return {} end
  return res
end

H.clear_namespace = function(...) pcall(vim.api.nvim_buf_clear_namespace, ...) end

H.is_buf_text = function(buf_id)
  local n = vim.api.nvim_buf_call(buf_id, function() return vim.fn.byte2line(1024) end)
  local lines = vim.api.nvim_buf_get_lines(buf_id, 0, n, false)
  return table.concat(lines, ''):find('\0') == nil
end

H.get_buftext = function(buf_id)
  local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
  -- - NOTE: Appending '\n' makes more intuitive diffs at end-of-file
  local text = table.concat(lines, '\n') .. '\n'
  if not vim.bo[buf_id].bomb then return text, lines end
  local bytes = H.bom_bytes[vim.bo[buf_id].fileencoding] or ''
  lines[1] = bytes .. lines[1]
  return bytes .. text, lines
end

-- Try getting buffer's full real path (after resolving symlinks)
H.get_buf_realpath = function(buf_id) return vim.loop.fs_realpath(vim.api.nvim_buf_get_name(buf_id)) or '' end

require('mini.diff.rendering').install(H)

return MiniDiff
