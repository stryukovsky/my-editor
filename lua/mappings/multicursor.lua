local map = require "mappings.map"
local mc = require "multicursor-nvim"

-- multi cursor
-- Add or skip cursor above/below the main cursor.
map({ "n", "x" }, "<S-A-Up>", function()
  mc.lineAddCursor(-1)
end)

map({ "n", "x" }, "<S-A-Down>", function()
  mc.lineAddCursor(1)
end)

-- Add or skip adding a new cursor by matching word/selection
map({ "n", "x" }, "<S-A-Right>", function()
  mc.matchAddCursor(1)
end)
map({ "n", "x" }, "<S-A-Left>", function()
  mc.matchAddCursor(-1)
end)

-- Add and remove cursors with control + left click.
map("n", "<c-leftmouse>", mc.handleMouse)
map("n", "<c-leftdrag>", mc.handleMouseDrag)
map("n", "<c-leftrelease>", mc.handleMouseRelease)

-- Disable and enable cursors.
map({ "n", "x" }, "<S-A-c>", mc.toggleCursor)

-- Mappings defined in a keymap layer only apply when there are
-- multiple cursors. This lets you have overlapping mappings.
mc.addKeymapLayer(function(layerSet)
  -- Select a different cursor as the main one.
  layerSet({ "n", "x" }, "<S-Up>", mc.prevCursor)
  layerSet({ "n", "x" }, "<S-Down>", mc.nextCursor)

  -- Delete the main cursor.
  layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)

  -- Enable and clear cursors using escape.
  layerSet("n", "<esc>", function()
    if not mc.cursorsEnabled() then
      mc.enableCursors()
    else
      mc.clearCursors()
    end
  end)
end)
