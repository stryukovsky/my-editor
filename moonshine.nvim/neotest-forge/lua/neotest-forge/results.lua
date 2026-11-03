local lib = require "neotest.lib"
local statuses = { Success = "passed", Failure = "failed", Skipped = "skipped" }

local function present(value)
  return value ~= nil and value ~= vim.NIL
end

local function summary(name, result)
  local lines = { result.status .. ": " .. name }
  if present(result.reason) then
    lines[#lines + 1] = result.reason
  end
  for _, line in ipairs(result.decoded_logs or {}) do
    lines[#lines + 1] = line
  end
  if present(result.counterexample) then
    lines[#lines + 1] = "Counterexample: " .. vim.inspect(result.counterexample)
  end
  return table.concat(lines, "\n")
end

return function(spec, result, tree)
  local read_ok, raw = pcall(lib.files.read, spec.context.report)
  local decode_ok, report = false, nil
  if read_ok then
    decode_ok, report = pcall(vim.json.decode, raw)
    vim.uv.fs_unlink(spec.context.report)
  end
  local tests, setup_failures = {}, {}
  if decode_ok and type(report) == "table" then
    for suite, data in pairs(report) do
      local path, contract = suite:match "^(.*):([^:]+)$"
      if path and type(data) == "table" then
        if not vim.startswith(path, "/") then
          path = spec.cwd .. "/" .. path
        end
        local prefix = vim.fs.normalize(path) .. "::" .. contract
        for signature, test in pairs(data.test_results or {}) do
          local name = signature:match "^([^%(]+)"
          if name then
            tests[prefix .. "::" .. name] = test
            if name == "setUp" and test.status == "Failure" then
              setup_failures[prefix] = test
            end
          end
        end
      end
    end
  end

  local results = {}
  for _, position in tree:iter() do
    if position.type == "test" then
      local test = tests[position.id]
      local setup = setup_failures[position.id:match "^(.*)::[^:]+$"]
      local status, short
      if test then
        status = statuses[test.status] or "failed"
        short = summary(position.name, test)
      elseif setup then
        status, short = "failed", summary("setUp", setup)
      elseif not decode_ok or result.code ~= 0 then
        status = "failed"
        short = "Forge did not report this test (exit "
          .. result.code
          .. "). See output for compiler or runner errors."
      else
        status, short =
          "skipped",
          "Forge did not run this test. Check filters and test visibility."
      end
      results[position.id] = {
        status = status,
        short = short,
        output = result.output,
        errors = status == "failed" and {
          { message = short, line = position.range[1] },
        } or {},
      }
    end
  end
  return results
end
