local map = require "mappings.map"

-- q and Q belong to native multicursors; disable macro replay as well.
map({ "n", "x" }, "@", "<Nop>", { desc = "Macros disabled" })
