local M = {}

function M.parse(patch)
  local hunks = {}
  for line in patch:gmatch "[^\n]+" do
    -- Only unprefixed metadata can classify a patch. Source lines may contain
    -- these exact strings behind their +/-/context prefix.
    if line:match "^Binary files .* differ$" or line == "GIT binary patch" then
      return nil, "Binary staged diff is unavailable"
    end
    if
      line:match "^%* Unmerged path "
      or line:match "^diff %-%-cc "
      or line:match "^diff %-%-combined "
    then
      return nil, "Unmerged index entries are unsupported"
    end
    local old, old_count, new, new_count =
      line:match "^@@ %-(%d+)(,?%d*) %+(%d+)(,?%d*) @@"
    if old then
      old_count = old_count == "" and 1 or tonumber(old_count:sub(2))
      new_count = new_count == "" and 1 or tonumber(new_count:sub(2))
      hunks[#hunks + 1] = {
        ref_start = tonumber(old),
        ref_count = old_count,
        buf_start = tonumber(new),
        buf_count = new_count,
        type = old_count == 0 and "add"
          or (new_count == 0 and "delete" or "change"),
      }
    end
  end
  return hunks
end

function M.load(read, cwd, basename, callback)
  -- Git handles unborn HEAD and paths absent from HEAD without inventing an
  -- empty baseline after an arbitrary failed `git show HEAD:path` operation.
  local args = {
    "diff",
    "--cached",
    "--no-color",
    "--no-ext-diff",
    "--no-textconv",
    "--no-renames",
    "--unified=0",
    "--inter-hunk-context=0",
    "--diff-algorithm=histogram",
    "--",
    ":(literal)" .. basename,
  }
  read(args, cwd, callback)
end

return M
