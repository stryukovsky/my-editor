local map = require "mappings.map"
local group = vim.api.nvim_create_augroup("LeanMappings", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "lean",
  callback = function(event)
    local bindings = {
      { "<leader>Lei", "LeanInfoviewToggle", "Toggle infoview" },
      { "<leader>Lej", "LeanGotoInfoview", "Go to infoview" },
      { "<leader>Leg", "LeanGoal", "Show goal" },
      { "<leader>Lep", "LeanInfoviewAddPin", "Pin goal" },
      { "<leader>Lec", "LeanInfoviewClearPins", "Clear goal pins" },
      { "<leader>Ler", "LeanRestartFile", "Restart file" },
      { "<leader>Lea", "LeanInfoviewAcceptSuggestion", "Accept suggestion" },
      { "K", "LeanHover", "Interactive hover" },
    }
    for _, binding in ipairs(bindings) do
      map(
        "n",
        binding[1],
        "<Cmd>" .. binding[2] .. "<CR>",
        { buffer = event.buf, desc = "Lean: " .. binding[3] }
      )
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "leaninfo",
  callback = function(event)
    map("n", "q", "<Cmd>close<CR>", { buffer = event.buf, desc = "Lean: Close infoview window" })
  end,
})
