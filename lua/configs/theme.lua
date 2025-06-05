local current_hour = tonumber(tostring(vim.fn.strftime "%H"))
if current_hour >= 20 or current_hour <= 7 then
  vim.cmd "colorscheme tokyonight-night"
else
  vim.cmd "colorscheme tokyonight-day"
end
