-- Derived display data only. H is the existing engine attachment/render seam;
-- hunk snapshots and readiness are owned by hunks_cache, never this module.
local M = {}
M.namespaces = {
  viz = vim.api.nvim_create_namespace "MiniDiffViz",
  overlay = vim.api.nvim_create_namespace "MiniDiffOverlay",
}

function M.install(H)
  -- nvim__redraw replaced nvim__buf_redraw_range during the 0.10 release cycle.
  H.redraw_buffer = function(buf)
    if vim.api.nvim__redraw then
      vim.api.nvim__redraw { buf = buf, valid = true, statusline = true }
    else
      vim.api.nvim__buf_redraw_range(buf, 0, -1)
      vim.cmd "redrawstatus"
    end
  end
  H.set_decoration_provider = function(ns_id_viz, ns_id_overlay)
    local on_win = function(_, _, buf_id, top, bottom)
      local cache = H.cache[buf_id]
      if not cache then
        return false
      end
      local viz, overlay = cache.viz_lines, cache.overlay_lines
      if cache.needs_clear then
        H.clear_all_diff(buf_id)
        cache.needs_clear, cache.dummy_extmark = false, nil
        -- Ensure that sign column is visible even if hunks are outside of window
        -- view (matters with `signcolumn=auto`).
        if cache.config.view.style == "sign" and not vim.tbl_isempty(viz) then
          cache.dummy_extmark =
            vim.api.nvim_buf_set_extmark(buf_id, ns_id_viz, 0, 0, {
              sign_text = "  ",
              priority = 0,
              right_gravity = false,
              sign_hl_group = "SignColumn",
              cursorline_hl_group = "CursorLineSign",
            })
        end
      end
      local has_viz = false
      for i = top + 1, bottom + 1 do
        if viz[i] then
          H.set_extmark(buf_id, ns_id_viz, i - 1, 0, viz[i])
          viz[i] = nil
          has_viz = true
        end
        if overlay[i] then
          -- Allow several overlays at one line (like for "delete" and "change").
          for _, data in ipairs(overlay[i]) do
            H.draw_overlay_line(buf_id, ns_id_overlay, i - 1, data)
          end
          overlay[i] = nil
        end
      end
      -- Clear dummy marks so they do not affect yes:2 / auto:2 sign columns.
      if cache.dummy_extmark and has_viz then
        vim.api.nvim_buf_del_extmark(buf_id, ns_id_viz, cache.dummy_extmark)
        cache.dummy_extmark = nil
      end
    end
    vim.api.nvim_set_decoration_provider(ns_id_viz, { on_win = on_win })
  end

  H.update_hunk_data = function(_, cache, buf_lines)
    local viz, overlay = {}, {}
    local ref_lines = cache.overlay and vim.split(cache.ref_text, "\n") or nil
    for _, hunk in ipairs(cache.hunks) do
      local from, to = H.get_hunk_buf_range(hunk)
      -- Register lines for draw. Prefer "change" over other types on a line.
      for line = from, to do
        if not viz[line] or hunk.type == "change" then
          viz[line] = cache.extmark_opts[hunk.type]
        end
      end
      if cache.overlay then
        if hunk.type == "add" then
          H.append_overlay_add(overlay, hunk, cache.config.view.priority)
        end
        if hunk.type == "change" then
          H.append_overlay_change(
            overlay,
            hunk,
            ref_lines,
            buf_lines,
            cache.config.view.priority
          )
        end
        if hunk.type == "delete" then
          H.append_overlay_delete(
            overlay,
            hunk,
            ref_lines,
            cache.config.view.priority
          )
        end
      end
    end
    cache.viz_lines, cache.overlay_lines = viz, overlay
  end

  H.update_staged_viz = function(buf_id, cache)
    local staged = require("mini.diff.hunks_cache.staged")._read(buf_id)
    if not staged or staged.status ~= "ready" then
      return
    end
    local unstaged_lines = vim.tbl_extend("force", {}, cache.viz_lines)
    for _, hunk in ipairs(staged.buffer_hunks) do
      local from, to = H.get_hunk_buf_range(hunk)
      local kind = hunk.type:sub(1, 1):upper() .. hunk.type:sub(2)
      for line = from, to do
        -- Both layers use the same drawable range/deletion-anchor rules.
        -- Keep the actual unstaged change visible instead of overwriting it.
        if not unstaged_lines[line] then
          local opts = vim.deepcopy(cache.extmark_opts[hunk.type])
          if cache.config.view.style == "sign" then
            opts.sign_text = "┆"
          end
          opts[H.style_extmark_data[cache.config.view.style].field] = "MiniDiffSignStaged"
            .. kind
          cache.viz_lines[line] = opts
        end
      end
    end
  end

  H.clear_all_diff = function(buf_id)
    H.clear_namespace(buf_id, H.ns_id.viz, 0, -1)
    H.clear_namespace(buf_id, H.ns_id.overlay, 0, -1)
  end

  H.append_overlay = function(lines, line, data)
    lines[line] = lines[line] or {}
    table.insert(lines[line], data)
  end
  H.append_overlay_add = function(lines, hunk, priority)
    -- Append one by one to have them reveal granularly when scrolling up.
    for line = hunk.buf_start, hunk.buf_start + hunk.buf_count - 1 do
      H.append_overlay(lines, line, { type = "add", priority = priority })
    end
  end
  H.append_overlay_change = function(
    lines,
    hunk,
    ref_lines,
    buf_lines,
    priority
  )
    -- For one-to-one change, show lines separately with word diff highlighted.
    if hunk.buf_count == hunk.ref_count then
      for i = 0, hunk.ref_count - 1 do
        -- Defer word diff until the decoration provider displays the line.
        H.append_overlay(lines, hunk.buf_start + i, {
          type = "change_worddiff",
          ref_line = ref_lines[hunk.ref_start + i],
          buf_line = buf_lines[hunk.buf_start + i],
          priority = priority,
        })
      end
      return
    end
    -- If not one-to-one change, show reference lines above first real one.
    local changed = {}
    for i = hunk.ref_start, hunk.ref_start + hunk.ref_count - 1 do
      changed[#changed + 1] =
        { { ref_lines[i] .. H.overlay_suffix, "MiniDiffOverChange" } }
    end
    H.append_overlay(lines, hunk.buf_start, {
      type = "change",
      lines = changed,
      show_above = true,
      priority = priority,
    })
    for line = hunk.buf_start + 1, hunk.buf_start + hunk.buf_count - 1 do
      H.append_overlay(lines, line, { type = "change", priority = priority })
    end
  end
  H.append_overlay_delete = function(lines, hunk, ref_lines, priority)
    local deleted = {}
    for i = hunk.ref_start, hunk.ref_start + hunk.ref_count - 1 do
      deleted[#deleted + 1] = {
        { ref_lines[i], "MiniDiffOverDelete" },
        { H.overlay_suffix, "MiniDiffOverDelete" },
      }
    end
    H.append_overlay(lines, math.max(hunk.buf_start, 1), {
      type = "delete",
      lines = deleted,
      show_above = hunk.buf_start == 0,
      priority = priority,
    })
  end

  H.draw_overlay_line = function(buf_id, ns_id, row, data)
    -- "Change worddiff" hunks show reference text above and changed spans over it.
    if data.type == "change_worddiff" then
      return H.draw_overlay_line_worddiff(buf_id, ns_id, row, data)
    end
    local opts = { priority = data.priority }
    if data.type ~= "delete" then
      opts.end_row, opts.end_col, opts.hl_eol = row + 1, 0, true
      opts.hl_group = data.type == "add" and "MiniDiffOverAdd"
        or "MiniDiffOverContextBuf"
    end
    opts.virt_lines, opts.virt_lines_above, opts.virt_lines_overflow =
      data.lines, data.show_above, H.extmark_virt_lines_overflow
    H.set_extmark(buf_id, ns_id, row, 0, opts)
  end
  H.draw_overlay_line_worddiff = function(buf_id, ns_id, row, data)
    local ref_line, buf_line, priority =
      data.ref_line, data.buf_line, data.priority
    local ref_parts, buf_parts =
      H.compute_worddiff_changed_parts(ref_line, buf_line)
    local virt_line, index = {}, 1
    for _, part in ipairs(ref_parts) do
      if index < part[1] then
        virt_line[#virt_line + 1] =
          { ref_line:sub(index, part[1] - 1), "MiniDiffOverContext" }
      end
      virt_line[#virt_line + 1] =
        { ref_line:sub(part[1], part[2]), "MiniDiffOverChange" }
      index = part[2] + 1
    end
    if index <= #ref_line then
      virt_line[#virt_line + 1] = { ref_line:sub(index), "MiniDiffOverContext" }
    end
    virt_line[#virt_line + 1] = { H.overlay_suffix, "MiniDiffOverContext" }
    H.set_extmark(buf_id, ns_id, row, 0, {
      virt_lines = { virt_line },
      virt_lines_above = true,
      virt_lines_overflow = H.extmark_virt_lines_overflow,
      priority = priority,
    })
    local off = vim.bo[buf_id].bomb
        and #(H.bom_bytes[vim.bo[buf_id].fileencoding] or "")
      or 0
    for _, part in ipairs(buf_parts) do
      H.set_extmark(buf_id, ns_id, row, part[1] - 1 - off, {
        end_row = row,
        end_col = part[2] - off,
        hl_group = "MiniDiffOverChangeBuf",
        priority = priority,
      })
    end
    H.set_extmark(buf_id, ns_id, row, 0, {
      end_row = row + 1,
      end_col = 0,
      hl_group = "MiniDiffOverContextBuf",
      hl_eol = true,
      priority = priority - 1,
    })
  end

  H.compute_worddiff_changed_parts = function(ref_line, buf_line)
    local old, old_starts, old_ends = H.slice_line(ref_line)
    local new, new_starts, new_ends = H.slice_line(buf_line)
    local diff, old_ranges, new_ranges =
      vim.diff(old, new, H.worddiff_opts), {}, {}
    for _, d in ipairs(diff) do
      if d[2] > 0 then
        old_ranges[#old_ranges + 1] =
          { old_starts[d[1]], old_ends[d[1] + d[2] - 1] }
      end
      if d[4] > 0 then
        new_ranges[#new_ranges + 1] =
          { new_starts[d[3]], new_ends[d[3] + d[4] - 1] }
      end
    end
    return old_ranges, new_ranges
  end
  H.str_utfindex = function(s, i)
    return vim.str_utfindex(s, "utf-32", i)
  end
  if vim.fn.has "nvim-0.11" == 0 then
    H.str_utfindex = function(s, i)
      return (vim.str_utfindex(s, i))
    end
  end
  H.slice_line = function(line)
    -- Intertwine every proper character with '\n'.
    local length = #line
    if H.str_utfindex(line) == length then
      local starts, ends = {}, {}
      for i = 1, length do
        starts[i], ends[i] = i, i
      end
      return line:gsub("(.)", "%1\n"), starts, ends
    end
    local parts, starts, ends = {}, vim.str_utf_pos(line), {}
    for i = 1, #starts - 1 do
      parts[#parts + 1], ends[#ends + 1] =
        line:sub(starts[i], starts[i + 1] - 1), starts[i + 1] - 1
    end
    parts[#parts + 1], ends[#ends + 1] =
      line:sub(starts[#starts], length), length
    return table.concat(parts, "\n") .. "\n", starts, ends
  end
end

function M.paint_preview(buf, old_lines, new_lines)
  local ns = vim.api.nvim_create_namespace "LargeHunkViewer"
  local function line(row, group)
    vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
      end_row = row + 1,
      end_col = 0,
      hl_group = group,
      hl_eol = true,
      hl_mode = "combine",
      priority = 10,
    })
  end
  local function span(row, from, to, group)
    if not from or not to or to < from then
      return
    end
    vim.api.nvim_buf_set_extmark(buf, ns, row, from - 1, {
      end_row = row,
      end_col = to,
      hl_group = group,
      hl_mode = "combine",
      priority = 20,
    })
  end
  local function slice(text)
    if text == "" then
      return "\n", {}, {}
    end
    if vim.str_utfindex(text, "utf-32") == #text then
      local starts, ends = {}, {}
      for i = 1, #text do
        starts[i], ends[i] = i, i
      end
      return text:gsub(".", "%1\n"), starts, ends
    end
    local parts, starts, ends = {}, vim.str_utf_pos(text), {}
    if not starts or #starts == 0 then
      return "\n", {}, {}
    end
    for i = 1, #starts - 1 do
      parts[#parts + 1], ends[#ends + 1] =
        text:sub(starts[i], starts[i + 1] - 1), starts[i + 1] - 1
    end
    parts[#parts + 1], ends[#ends + 1] = text:sub(starts[#starts]), #text
    return table.concat(parts, "\n") .. "\n", starts, ends
  end
  for i = 1, #old_lines do
    line(i - 1, "MiniDiffOverDelete")
  end
  for i = 1, #new_lines do
    line(#old_lines + i - 1, "MiniDiffOverAdd")
  end
  local aligned
  if #old_lines == 0 or #new_lines == 0 then
    aligned = { { 1, #old_lines, 1, #new_lines } }
  else
    aligned = vim.diff(
      table.concat(old_lines, "\n") .. "\n",
      table.concat(new_lines, "\n") .. "\n",
      {
        algorithm = "histogram",
        result_type = "indices",
        indent_heuristic = true,
        linematch = 60,
      }
    )
  end
  for _, hunk in ipairs(aligned) do
    if hunk[2] > 0 and hunk[2] == hunk[4] then
      for i = 0, hunk[2] - 1 do
        local old, old_starts, old_ends = slice(old_lines[hunk[1] + i] or "")
        local new, new_starts, new_ends = slice(new_lines[hunk[3] + i] or "")
        local diff = vim.diff(old, new, {
          algorithm = "minimal",
          result_type = "indices",
          ctxlen = 0,
          interhunkctxlen = 4,
          indent_heuristic = false,
          linematch = 0,
        })
        for _, edit in ipairs(diff) do
          if edit[2] > 0 then
            span(
              hunk[1] + i - 1,
              old_starts[edit[1]],
              old_ends[edit[1] + edit[2] - 1],
              "MiniDiffOverChange"
            )
          end
          if edit[4] > 0 then
            span(
              #old_lines + hunk[3] + i - 1,
              new_starts[edit[3]],
              new_ends[edit[3] + edit[4] - 1],
              "MiniDiffOverChangeBuf"
            )
          end
        end
      end
    end
  end
end

return M
