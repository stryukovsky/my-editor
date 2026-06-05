-- local big_file_group = vim.api.nvim_create_augroup("BigFileDisableTS", { clear = true })
--
-- vim.api.nvim_create_autocmd({ "BufReadPre", "FileReadPre" }, {
--   group = big_file_group,
--   pattern = "*",
--   callback = function(args)
--     -- Define your large file threshold (e.g., 500 KB)
--     local max_filesize = 500 * 1024
--     local filepath = args.match
--
--     local ok, stats = pcall(vim.uv.fs_stat, filepath)
--     if ok and stats and stats.size > max_filesize then
--       -- 1. Completely stop and detach Tree-sitter for this buffer
--       vim.treesitter.stop(args.buf)
--
--       -- 2. Prevent standard regex syntax fallback if desired
--       vim.cmd "syntax off"
--
--       -- 3. Optional performance tweaks for giant buffers
--       vim.opt_local.foldmethod = "manual"
--       vim.opt_local.undofile = false
--       vim.opt_local.swapfile = false
--     end
--   end,
-- })

local big_file_group = vim.api.nvim_create_augroup("BigFilePerformance", { clear = true })

vim.api.nvim_create_autocmd({ "BufReadPre", "FileReadPre" }, {
  group = big_file_group,
  pattern = "*",
  callback = function(args)
    local max_filesize = 1000 * 1024 -- 1 МБ (настройте под себя)
    local filepath = args.match
    local ok, stats = pcall(vim.uv.fs_stat, filepath)

    if ok and stats and stats.size > max_filesize then
      -- Объявляем глобальную/буферную переменную, чтобы другие плагины знали о лимите
      vim.b[args.buf].large_file = true

      -- Отключаем тяжелые базовые механизмы Neovim
      vim.cmd "syntax off"
      -- vim.opt_local.eventignore:append { "BufEnter", "BufWinEnter", "WinEnter" } -- Блокирует фризы при переключении
      vim.opt_local.foldmethod = "manual"
      vim.opt_local.spell = false
      vim.opt_local.swapfile = false
      vim.opt_local.undofile = false
      vim.opt_local.filetype = "" -- Отключает автокоманды типов файлов
    end
  end,
})

-- Дополнительно принудительно останавливаем Tree-sitter при загрузке буфера
vim.api.nvim_create_autocmd("BufReadPost", {
  group = big_file_group,
  pattern = "*",
  callback = function(args)
    if vim.b[args.buf].large_file then
      pcall(vim.treesitter.stop, args.buf)
    end
  end,
})
