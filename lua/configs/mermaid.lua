local M = {}
local async = require "plenary.async"
local notify = require "configs.notify"
local open_scratch = require "utils.open_scratch"

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

local function mermaid_ascii_bin()
  local bundled = vim.fn.stdpath "config" .. "/bin/mermaid-ascii"
  if vim.fn.executable(bundled) == 1 then
    return bundled
  end
  if vim.fn.executable "mermaid-ascii" == 1 then
    return "mermaid-ascii"
  end
end

local function run(command, options, callback)
  async.run(function()
    local result = async.wrap(vim.system, 3)(command, options)
    vim.schedule(function()
      callback(result)
    end)
  end, function() end)
end

local function open_buffer(out_lines)
  open_scratch {
    name = "mermaid-preview",
    filetype = "mermaid-preview",
    lines = out_lines,
    buftype = "",
  }
end

---Mermaid source inside the ```mermaid fence under the cursor, if any.
---@param buf? integer
---@return string[]|nil
function M.fence_at_cursor(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  local open_row
  for i = row, 0, -1 do
    local lang = lines[i + 1]:match "^%s*```%s*(%S*)"
    if lang then
      if lang:lower() ~= "mermaid" then
        return nil
      end
      open_row = i
      break
    end
  end
  if not open_row then
    return nil
  end

  for i = open_row + 1, #lines - 1 do
    if lines[i + 1]:match "^%s*```%s*$" then
      if row < open_row or row >= i then
        return nil
      end
      return vim.list_slice(lines, open_row + 2, i)
    end
  end
end

function M.visualize(lines)
  if not lines or #lines == 0 or vim.trim(table.concat(lines, "")) == "" then
    notify.send("Mermaid", "No diagram to visualize", vim.log.levels.ERROR)
    return
  end

  local bin = mermaid_ascii_bin()
  if not bin then
    notify.send("Mermaid", "cannot render mermaid: mermaid-ascii needed", vim.log.levels.ERROR)
    return
  end

  local key = hash_input(lines)
  if cache[key] then
    open_buffer(cache[key])
    return
  end

  run({ bin, "-f", "-" }, {
    text = true,
    stdin = table.concat(lines, "\n") .. "\n",
  }, function(result)
    if result.code ~= 0 then
      notify.send("Mermaid", "Rendering failed: " .. ((result.stderr or "exit code ") .. result.code), vim.log.levels.ERROR)
      return
    end
    if not result.stdout or result.stdout == "" then
      notify.send("Mermaid", "Rendering produced no output", vim.log.levels.WARN)
      return
    end

    local out_lines = vim.split(result.stdout, "\n", { plain = true })
    if #cache_order >= MAX_CACHE then
      local oldest = table.remove(cache_order, 1)
      cache[oldest] = nil
    end
    cache[key] = out_lines
    table.insert(cache_order, key)
    open_buffer(out_lines)
  end)
end

local function output_path()
  local source_path = vim.api.nvim_buf_get_name(0)
  if source_path ~= "" then
    return vim.fn.fnamemodify(source_path, ":r") .. ".png"
  end
  local cache_dir = vim.fn.stdpath "cache" .. "/mermaid"
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

local function puppeteer_config()
  local dir = vim.fn.stdpath "cache" .. "/mermaid"
  vim.fn.mkdir(dir, "p")
  local path = dir .. "/puppeteer.json"
  local chrome = vim.fn.exepath "google-chrome"
  if chrome == "" then
    chrome = vim.fn.exepath "google-chrome-stable"
  end
  local config = { args = { "--no-sandbox", "--disable-gpu" } }
  if chrome ~= "" then
    config.executablePath = chrome
  end
  vim.fn.writefile({ vim.json.encode(config) }, path)
  return path
end

local function image_command(input, output, config_path)
  local mmdc = vim.fn.exepath "mmdc"
  if mmdc ~= "" then
    return { mmdc, "-i", input, "-o", output, "-p", config_path }
  end
  if vim.fn.executable "npx" == 1 then
    return {
      "npx",
      "--yes",
      "-p",
      "@mermaid-js/mermaid-cli",
      "mmdc",
      "-i",
      input,
      "-o",
      output,
      "-p",
      config_path,
    }
  end
end

function M.render_png(lines)
  if not lines or #lines == 0 or vim.trim(table.concat(lines, "")) == "" then
    notify.send("Mermaid", "No diagram to render", vim.log.levels.ERROR)
    return
  end

  local image_viewer = default_image_viewer()
  if not image_viewer then
    notify.send("Mermaid", "PNG rendering is only supported on macOS and Linux", vim.log.levels.ERROR)
    return
  end

  local path = output_path()
  local dir = vim.fn.fnamemodify(path, ":h")
  vim.fn.mkdir(dir, "p")
  local input = vim.fn.tempname() .. ".mmd"
  vim.fn.writefile(vim.split(table.concat(lines, "\n") .. "\n", "\n", { plain = true }), input)

  local config_path = puppeteer_config()
  local command = image_command(input, path, config_path)
  if not command then
    notify.send("Mermaid", "mmdc was not found. Install @mermaid-js/mermaid-cli to render images", vim.log.levels.ERROR)
    return
  end
  if command[1] == "npx" then
    notify.send("Mermaid", "Rendering image with mermaid-cli (first run may download it)", vim.log.levels.INFO)
  end

  local chrome = vim.fn.exepath "google-chrome"
  local env = { PUPPETEER_SKIP_DOWNLOAD = "1" }
  if chrome ~= "" then
    env.PUPPETEER_EXECUTABLE_PATH = chrome
  end
  run(command, {
    text = true,
    env = env,
  }, function(result)
    vim.fn.delete(input)
    if result.code ~= 0 then
      notify.send("Mermaid", "Rendering failed: " .. ((result.stderr or "exit code ") .. result.code), vim.log.levels.ERROR)
      return
    end
    vim.system({ image_viewer, path }, {}, function(open_result)
      if open_result.code ~= 0 then
        vim.schedule(function()
          notify.send("Mermaid", "Could not open PNG: " .. (open_result.stderr or path), vim.log.levels.ERROR)
        end)
      end
    end)
  end)
end

return M
