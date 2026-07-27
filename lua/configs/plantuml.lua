local M = {}
local async = require "plenary.async"

local cache = {}
local cache_order = {}
local MAX_CACHE = 10

local function hash_input(lines)
  local str = table.concat(lines, "\n")
  local h = 0
  for i = 1, #str do
    h = (h * 31 + string.byte(str, i)) % 2 ^ 31
  end
  return tostring(h)
end

local function open_buffer(out_lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "plantuml-preview"
  vim.bo[buf].buftype = ""
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buflisted = true

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, out_lines)
  vim.bo[buf].modified = false
  vim.bo[buf].modifiable = false

  vim.api.nvim_set_current_buf(buf)
  vim.wo.wrap = false

  local ok = pcall(vim.api.nvim_buf_set_name, buf, "plantuml-preview")
  if not ok then
    vim.api.nvim_buf_set_name(buf, "plantuml-preview" .. math.random(9999))
  end
end

local function run_plantuml(command, options, callback)
  async.run(function()
    local result = async.wrap(vim.system, 3)(command, options)
    vim.schedule(function()
      callback(result)
    end)
  end)
end

function M.visualize(lines)
  if not lines or #lines == 0 then
    vim.notify("No lines to visualize", vim.log.levels.ERROR)
    return
  end

  local key = hash_input(lines)
  if cache[key] then
    open_buffer(cache[key])
    return
  end

  local input = table.concat(lines, "\n") .. "\n"

  run_plantuml(
    { "plantuml", "-utxt", "-p" },
    {
      text = true,
      stdin = input,
    },
    function(result)
      if result.code ~= 0 then
        vim.notify("plantuml failed: " .. ((result.stderr or "exit code ") .. result.code), vim.log.levels.ERROR)
        return
      end

      local output = result.stdout
      if not output or #output == 0 then
        vim.notify("plantuml produced no output", vim.log.levels.WARN)
        return
      end

      local out_lines = vim.split(output, "\n", { plain = true })

      if #cache_order >= MAX_CACHE then
        local oldest = table.remove(cache_order, 1)
        cache[oldest] = nil
      end
      cache[key] = out_lines
      table.insert(cache_order, key)

      open_buffer(out_lines)
    end
  )
end

local function output_path()
  local source_path = vim.api.nvim_buf_get_name(0)
  if source_path ~= "" then
    return vim.fn.fnamemodify(source_path, ":r") .. ".png"
  end

  local cache_dir = vim.fn.stdpath "cache" .. "/plantuml"
  vim.fn.mkdir(cache_dir, "p")
  return cache_dir .. "/diagram.png"
end

local function default_image_viewer()
  local system = vim.uv.os_uname().sysname
  if system == "Darwin" then
    return "open"
  end
  if system == "Linux" then
    return "xdg-open"
  end
end

function M.render_png(lines)
  if not lines or #lines == 0 then
    vim.notify("No lines to render", vim.log.levels.ERROR)
    return
  end

  local image_viewer = default_image_viewer()
  if not image_viewer then
    vim.notify("PlantUML PNG rendering is only supported on macOS and Fedora Linux", vim.log.levels.ERROR)
    return
  end

  run_plantuml(
    { "plantuml", "-tpng", "-pipe" },
    {
      stdin = table.concat(lines, "\n") .. "\n",
    },
    function(result)
      if result.code ~= 0 then
        vim.notify("plantuml failed: " .. ((result.stderr or "exit code ") .. result.code), vim.log.levels.ERROR)
        return
      end
      if not result.stdout or #result.stdout == 0 then
        vim.notify("plantuml produced no PNG output", vim.log.levels.WARN)
        return
      end

      local path = output_path()
      local file, err = vim.uv.fs_open(path, "w", 420)
      if not file then
        vim.notify("Could not write PNG: " .. err, vim.log.levels.ERROR)
        return
      end

      local success, write_err = vim.uv.fs_write(file, result.stdout, 0)
      vim.uv.fs_close(file)
      if not success then
        vim.notify("Could not write PNG: " .. write_err, vim.log.levels.ERROR)
        return
      end

      vim.system({ image_viewer, path }, {}, function(open_result)
        if open_result.code ~= 0 then
          vim.schedule(function()
            vim.notify("Could not open PNG: " .. (open_result.stderr or path), vim.log.levels.ERROR)
          end)
        end
      end)
    end
  )
end

return M
