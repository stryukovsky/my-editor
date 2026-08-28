--- Close Zen mode and open the Neogit status view.
return function()
  require("utils.close_zen")()
  require("neogit").open {}
end
