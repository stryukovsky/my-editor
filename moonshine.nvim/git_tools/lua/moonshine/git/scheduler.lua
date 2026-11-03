local notify = require "integrations.notify"
local M = { busy = nil }
local queue = {}
local start

-- One queue and one active action, only for this Neovim session. Returning true
-- from a callback means it is waiting for another callback; otherwise it ends.
start = function(request)
  local lease = { name = request.name, cwd = request.cwd }
  M.busy = lease

  function lease:finish()
    if M.busy ~= self then
      return
    end
    M.busy = nil
    local next_request = table.remove(queue, 1)
    if next_request then
      start(next_request)
    end
  end

  function lease:call(fn, ...)
    if M.busy ~= self then
      return
    end
    local ok, waiting = pcall(fn, ...)
    if not ok then
      -- Keep callback/notification failures from leaving the session busy.
      pcall(notify.send, "Git", tostring(waiting), vim.log.levels.ERROR)
      if request.on_error then
        pcall(request.on_error, waiting)
      end
    end
    if not ok or waiting ~= true then
      self:finish()
    end
  end

  function lease:callback(fn)
    local called = false
    return function(...)
      if called then
        return
      end
      called = true
      self:call(fn, ...)
    end
  end

  function lease:input(opts, fn)
    vim.ui.input(opts, self:callback(fn))
    return true
  end

  function lease:schedule(fn)
    vim.schedule(self:callback(fn))
    return true
  end

  lease:call(request.run, lease)
end

function M.blocked()
  if M.busy then
    notify.send(
      "Git",
      M.busy.name .. " is running; try again when it finishes",
      vim.log.levels.WARN
    )
    return true
  end
  return false
end

function M.write(name, cwd, run)
  if M.blocked() then
    return false
  end
  start { name = name, cwd = cwd, run = run }
  return true
end

function M.submit(name, cwd, run, on_error)
  local request = { name = name, cwd = cwd, run = run, on_error = on_error }
  if M.busy then
    queue[#queue + 1] = request
    notify.send("Git", name .. " queued: " .. cwd)
  else
    start(request)
  end
end

-- Picker handlers share this wrapper for direct shortcuts and menu choices.
function M.wrap(name, handler)
  return function(context)
    return M.write(name, context.cwd, function(lease)
      return handler(context, lease)
    end)
  end
end

return M
