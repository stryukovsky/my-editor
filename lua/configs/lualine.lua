local trouble = require "trouble"
local is_ollama_installed = require "utils.is_ollama_installed"
local dap_output = require "configs.debug_output"
local git_fetch = require "configs.periodic-git-fetch"
local symbols = trouble.statusline {
  mode = "lsp_document_symbols",
  groups = {},
  title = false,
  filter = { range = true },
  format = "{kind_icon}{symbol.name:Normal}",
  -- The following line is needed to fix the background color
  -- Set it to the lualine section you want to use
  hl_group = "lualine_c_normal",
}

local function gitsigns_hunk_status()
  -- Проверяем, активен ли gitsigns в буфере
  if not vim.b.gitsigns_status_dict then
    return ""
  end

  local ok, gitsigns = pcall(require, "gitsigns")
  if not ok then
    return ""
  end

  local hunks = gitsigns.get_hunks()
  if not hunks or #hunks == 0 or #hunks > 1000 then
    return "" -- Изменений нет
  end

  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_hunk_idx = nil
  for idx, hunk in ipairs(hunks) do
    local start_line, end_line

    if hunk.type == "delete" then
      -- Для удалений: курсор считается «внутри», если он на строке старта
      -- или gitsigns отрисовывает маркер удаления вокруг этой строки
      start_line = hunk.added.start
      end_line = hunk.added.start
    else
      -- Для add и change: строки физически присутствуют в файле
      start_line = hunk.added.start
      -- Если count равен 0 (на всякий случай), берем старт, иначе вычисляем конец
      end_line = hunk.added.start + math.max(0, hunk.added.count - 1)
    end

    -- Проверяем, входит ли курсор в диапазон данного ханка
    if current_line >= start_line and current_line <= end_line then
      current_hunk_idx = idx
      break
    end
  end
  -- Перебираем все ханки и проверяем, входит ли текущая строка в их диапазон
  -- for idx, hunk in ipairs(hunks) do
  --   -- gitsigns возвращает координаты начала и конца изменений
  --   local start_line = hunk.added.start
  --   local end_line = start_line + hunk.added.count
  --
  --   -- Особый случай для удаленных строк (когда новых строк добавлено 0)
  --   if hunk.added.count == 0 then
  --     end_line = start_line
  --   end
  --
  --   -- Если курсор находится в границах ханка
  --   if current_line >= start_line and current_line <= end_line then
  --     current_hunk_idx = idx
  --     break
  --   end
  -- end

  -- Форматируем вывод
  if current_hunk_idx then
    return string.format(" hunk %d/%d", current_hunk_idx, #hunks) -- Например:    2/5 (если внутри)
  else
    return string.format(" hunks %d", #hunks) -- Например:    5 (если курсор снаружи)
  end
end

local function to_hex_color(color)
  return "#" .. string.format("%x", color)
end

local defaults_for_x_component = { "lsp_status", "filetype" }
local function lualine_x_component()
  if not is_ollama_installed() then
    return defaults_for_x_component
  end
  local success, config = pcall(function()
    return vim.list_extend({
      require "minuet.lualine",
    }, defaults_for_x_component)
  end)
  if success then
    return config
  else
    return defaults_for_x_component
  end
end

local function get_lualine_theme()
  local bg_color = to_hex_color(vim.api.nvim_get_hl(0, { name = "Normal" }).bg)
  local fg_color = to_hex_color(vim.api.nvim_get_hl(0, { name = "Normal" }).fg)
  local lualine_theme = require "lualine.themes.auto"
  -- lualine_theme.normal.c.bg = bg_color
  -- lualine_theme.normal.b.bg = bg_color
  for k, _ in pairs(lualine_theme) do
    lualine_theme[k].b.bg = bg_color
    lualine_theme[k].c.bg = bg_color
    lualine_theme[k].b.fg = fg_color
    lualine_theme[k].c.fg = fg_color
  end
  lualine_theme.replace.a = { fg = "#ffffff", bg = "#ff0000" }
  lualine_theme.replace.z = { fg = "#ffffff", bg = "#ff0000" }
  lualine_theme.visual.a = { fg = "#ffffff", bg = "#0000ff" }
  lualine_theme.visual.z = { fg = "#ffffff", bg = "#0000ff" }

  return lualine_theme
end

vim.api.nvim_create_autocmd({ "ColorScheme" }, {
  pattern = "*",
  callback = function()
    require("lualine").setup {
      options = {
        theme = get_lualine_theme(),
      },
    }
  end,
})

require("lualine").setup {
  options = {
    theme = get_lualine_theme(),
    globalstatus = true,
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { git_fetch.lualine_component(), "branch", { gitsigns_hunk_status } },
    lualine_c = {
      {
        "filename",
        file_status = true, -- Displays file status (readonly status, modified status)
        newfile_status = false, -- Display new file status (new file means no write after created)
        path = 3, -- 0: Just the filename
        -- 1: Relative path
        -- 2: Absolute path
        -- 3: Absolute path, with tilde as the home directory
        -- 4: Filename and parent dir, with tilde as the home directory

        shorting_target = 40, -- Shortens path to leave 40 spaces in the window
        -- for other components. (terrible name, any suggestions?)
        symbols = {
          modified = "[+]", -- Text to show when the file is modified.
          readonly = "[-]", -- Text to show when the file is non-modifiable or readonly.
          unnamed = "[No Name]", -- Text to show for unnamed buffers.
          newfile = "[New]", -- Text to show for newly created file before first write
        },
      },
      {
        symbols.get,
        cond = symbols.has,
      },
    },

    lualine_x = lualine_x_component(),
    -- lualine_y = {
    --   {
    --     function()
    --       return "󰛢"
    --     end,
    --     cond = function()
    --       return package.loaded["grapple"] and require("grapple").exists()
    --     end,
    --   },
    -- },
    lualine_y = { dap_output.lualine_component() },
    lualine_z = { "location", "selectioncount" },
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {},
}
