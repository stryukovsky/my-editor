local map = require "mappings.map"
local mc = require "multicursor-nvim"

-- multi cursor
-- Add or skip cursor above/below the main cursor.
map({ "n", "x" }, "<C-A-K>", function()
  mc.lineAddCursor(-1)
end, { desc = "Multicursor: add on prev line" })

map({ "n", "x" }, "<C-A-J>", function()
  mc.lineAddCursor(1)
end, { desc = "Multicursor: add on next line" })

-- Add or skip adding a new cursor by matching word/selection
map({ "n", "x" }, "<C-A-L>", function()
  mc.matchAddCursor(1)
end, { desc = "Multicursor: add next match" })
map({ "n", "x" }, "<C-A-H>", function()
  mc.matchAddCursor(-1)
end, { desc = "Multicursor: add prev match" })

-- Add and remove cursors with control + left click.
map("n", "<c-leftmouse>", mc.handleMouse)
map("n", "<c-leftdrag>", mc.handleMouseDrag)
map("n", "<c-leftrelease>", mc.handleMouseRelease)

-- Disable and enable cursors.
map({ "n", "x" }, "<leader>C", mc.toggleCursor, { desc = "Multicursor: toggle cursor" })

-- Mappings defined in a keymap layer only apply when there are
-- multiple cursors. This lets you have overlapping mappings.
mc.addKeymapLayer(function(layerSet)
  -- Select a different cursor as the main one.
  layerSet({ "n", "x" }, "<A-Up>", mc.prevCursor)
  layerSet({ "n", "x" }, "<A-Down>", mc.nextCursor)


  layerSet({ "n", "x" }, "<S-Up>", mc.prevCursor)
  layerSet({ "n", "x" }, "<S-Down>", mc.nextCursor)
  -- Delete the main cursor.
  layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)
  layerSet({ "n", "x" }, "<A-x>", mc.deleteCursor)
  layerSet({ "n", "x" }, "<C-A-X>", mc.deleteCursor)
  layerSet({ "n", "x" }, "<C-A-x>", mc.deleteCursor)

  -- Enable and clear cursors using escape.
  layerSet("n", "<esc>", function()
    if not mc.cursorsEnabled() then
      mc.enableCursors()
    else
      mc.clearCursors()
    end
  end)
end)
