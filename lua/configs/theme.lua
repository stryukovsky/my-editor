local current_hour = tonumber(tostring(vim.fn.strftime "%H"))
if current_hour >= 22 then
  vim.cmd "colorscheme tokyonight-night"
else
  vim.cmd "colorscheme tokyonight-day"
end
