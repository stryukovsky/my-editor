--- Close UI components that conflict with opening or focusing another component.
---@return boolean zen_was_closed
return function()
  return require("moonshine.utils.close_zen")()
end
