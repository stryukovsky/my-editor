return function(path)
  
      local sysname = vim.loop.os_uname().sysname
      if sysname == "Darwin" then
        vim.fn.jobstart({ "open", path }, { detach = true })
      elseif sysname == "Linux" then
        vim.fn.jobstart({ "nautilus", "--select", path }, { detach = true })
      elseif sysname == "Windows_NT" then
        vim.fn.jobstart({ "explorer", path }, { detach = true })
      else
        vim.notify("Unknown platform: " .. sysname, vim.log.levels.ERROR)
      end
end
