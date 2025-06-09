local manager = require "neo-tree.sources.manager"
local commands = require "neo-tree.sources.filesystem.commands"
commands.refresh(manager.get_state "filesystem")
