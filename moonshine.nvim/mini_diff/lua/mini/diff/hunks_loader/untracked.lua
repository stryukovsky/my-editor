local M = {}

function M.load(read, cwd, basename, current, callback)
  -- Missing stage zero can mean untracked, ignored, or unmerged. Only a
  -- confirmed nonignored path absent from the index gets an empty baseline.
  read(
    { "ls-files", "--stage", "-z", "--", ":(literal)" .. basename },
    cwd,
    function(code, entries, err)
      if not current() then
        return
      end
      if code ~= 0 or err or entries ~= "" then
        return callback(1, "", err, false)
      end
      read(
        { "check-ignore", "--quiet", "--", basename },
        cwd,
        function(ignore_code, _, ignore_err)
          if not current() then
            return
          end
          if ignore_code == 1 and not ignore_err then
            return callback(0, "", nil, true)
          end
          callback(1, "", ignore_err, false)
        end
      )
    end
  )
end

return M
