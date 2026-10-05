local linux_cmd

local function linux_open(path)
  if not linux_cmd then
    if vim.fn.executable "nemo" == 1 then
      linux_cmd = { "nemo" }
    else
      linux_cmd = { "nautilus", "--select" }
    end
  end
  local cmd = vim.deepcopy(linux_cmd)
  cmd[#cmd + 1] = path
  vim.fn.jobstart(cmd, { detach = true })
end

return function(path)
  local sysname = vim.loop.os_uname().sysname
  if sysname == "Darwin" then
    vim.fn.jobstart({ "open", "-R", path }, { detach = true })
  elseif sysname == "Linux" then
    linux_open(path)
  elseif sysname == "Windows_NT" then
    vim.fn.jobstart({ "explorer", path }, { detach = true })
  else
    vim.notify("Unknown platform: " .. sysname, vim.log.levels.ERROR)
  end
end
