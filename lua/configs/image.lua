local M = {}

local scale_factor = 1.0
local scale_step = 0.8

local options = {
  processor = "magick_cli",
}

function M.setup()
  options.scale_factor = scale_factor
  require("image").setup(options)
end

function M.adjust_scale(change)
  scale_factor = math.max(0.1, math.floor((scale_factor + change) * 100 + 0.5) / 100)
  M.setup()

  for _, image in ipairs(require("image").get_images()) do
    image:clear()
    image:render()
  end

  vim.notify(("Image scale: %.0f%%"):format(scale_factor * 100))
end

function M.increase_scale()
  M.adjust_scale(scale_step)
end

function M.decrease_scale()
  M.adjust_scale(-scale_step)
end

return M
