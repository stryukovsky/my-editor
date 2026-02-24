local current_hour = tonumber(tostring(vim.fn.strftime "%H"))

if current_hour >= 20 or current_hour <= 7 then
  vim.o.background = "dark"
  vim.cmd.colorscheme "material-deep-ocean"
else
  vim.o.background = "light"
  vim.cmd.colorscheme "material-lighter"
end
