--- Close conflicting UI and open the Neogit status view.
return function()
  require("utils.ui_prevent_mess")()
  require("neogit").open {}
end
