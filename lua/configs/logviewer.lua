-- Function to remove all lines containing a specific string from current buffer
-- Optimized for large files by processing in reverse order and batching operations
return function(search_string, use_pattern)
  if not search_string or search_string == "" then
    print "Error: Search string cannot be empty"
    return
  end

  -- Get current buffer
  local buf = vim.api.nvim_get_current_buf()
  local total_lines = vim.api.nvim_buf_line_count(buf)

  if total_lines == 0 then
    print "Buffer is empty"
    return
  end

  -- For very large files, show progress
  local show_progress = total_lines > 10000
  local progress_interval = math.floor(total_lines / 20) -- Update progress 20 times

  -- Collect line numbers to delete (in reverse order for efficient deletion)
  local lines_to_delete = {}
  local processed = 0

  if show_progress then
    print(string.format("Processing %d lines...", total_lines))
  end

  -- Process lines in chunks to avoid memory issues with huge files
  local chunk_size = 1000
  local start_line = 0

  while start_line < total_lines do
    local end_line = math.min(start_line + chunk_size - 1, total_lines - 1)
    local lines = vim.api.nvim_buf_get_lines(buf, start_line, end_line + 1, false)

    -- Check each line in current chunk
    for i, line in ipairs(lines) do
      local line_num = start_line + i
      local found = false

      if use_pattern then
        -- Use Lua pattern matching
        found = string.find(line, search_string) ~= nil
      else
        -- Simple string search (faster)
        found = string.find(line, search_string, 1, true) ~= nil
      end

      if found then
        -- Store as 0-indexed for nvim_buf_del_lines
        table.insert(lines_to_delete, 1, line_num - 1)
      end

      processed = processed + 1

      -- Show progress for large files
      if show_progress and processed % progress_interval == 0 then
        local percent = math.floor((processed / total_lines) * 100)
        print(string.format("Progress: %d%% (%d/%d lines)", percent, processed, total_lines))
      end
    end

    start_line = end_line + 1
  end

  -- Delete lines in batches (reverse order to maintain line numbers)
  local deleted_count = #lines_to_delete

  if deleted_count == 0 then
    print(string.format("No lines found containing '%s'", search_string))
    return
  end

  if show_progress then
    print(string.format("Deleting %d lines...", deleted_count))
  end

  -- Delete in batches to improve performance
  local batch_size = 100
  local batches_processed = 0
  local total_batches = math.ceil(deleted_count / batch_size)

  for i = 1, deleted_count, batch_size do
    local batch_end = math.min(i + batch_size - 1, deleted_count)
    local batch_lines = {}

    -- Collect consecutive line ranges for efficient deletion
    local range_start = lines_to_delete[i]
    local range_count = 1

    for j = i + 1, batch_end do
      if lines_to_delete[j] == range_start - range_count then
        range_count = range_count + 1
      else
        -- Delete current range
        vim.api.nvim_buf_set_lines(buf, range_start - range_count + 1, range_start + 1, false, { "" })
        -- Start new range
        range_start = lines_to_delete[j]
        range_count = 1
      end
    end

    -- Delete final range
    vim.api.nvim_buf_set_lines(buf, range_start - range_count + 1, range_start + 1, false, { "" })

    batches_processed = batches_processed + 1

    if show_progress and total_batches > 5 then
      local percent = math.floor((batches_processed / total_batches) * 100)
      print(string.format("Deletion progress: %d%%", percent))
    end
  end

  print(string.format("Removed %d lines containing '%s'", deleted_count, search_string))
end
