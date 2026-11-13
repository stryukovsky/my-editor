require("moonshine.jumper").setup()

vim.api.nvim_create_user_command("JumperDelete", function(args)
  require("moonshine.jumper").delete(args.args)
end, {
  nargs = 1,
  complete = function()
    local jumper = require "moonshine.jumper"
    local names = {}
    for code = string.byte("a"), string.byte("z") do
      local name = string.char(code)
      if jumper.get(name) then
        names[#names + 1] = name
      end
    end
    return names
  end,
  desc = "Delete a named global jumper mark",
})
