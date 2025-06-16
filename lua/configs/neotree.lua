---@diagnostic disable: param-type-mismatch, unused-local, missing-fields, redundant-parameter
---
local filesystem = require "neo-tree.sources.filesystem"
local renderer = require "neo-tree.ui.renderer"
local telescope = require "telescope.builtin"
local function open_single_child_dir_recursively(state)
  local node = state.tree:get_node()
  if node.type == "directory" then
    if not node:is_expanded() then
      filesystem.toggle_directory(state, node, nil, nil, nil, function()
        local children_count = #node:get_child_ids()
        if children_count >= 1 then
          renderer.focus_node(state, node:get_child_ids()[1])
        end
        if children_count == 1 then
          local first_child_node = state.tree:get_node()
          if first_child_node.type == "directory" then
            open_single_child_dir_recursively(state)
          end
        end
      end)
    elseif node:has_children() then
      renderer.focus_node(state, node:get_child_ids()[1])
    end
  end
end

local function getTelescopeOpts(state, path)
  return {
    cwd = path,
    search_dirs = { path },
    attach_mappings = function(prompt_bufnr, map)
      local actions = require "telescope.actions"
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local action_state = require "telescope.actions.state"
        local selection = action_state.get_selected_entry()
        local filename = selection.filename
        if filename == nil then
          filename = selection[1]
        end
        -- any way to open the file without triggering auto-close event of neo-tree?
        require("neo-tree.sources.filesystem").navigate(state, state.path, filename)
      end)
      return true
    end,
  }
end

---@type neotree.Config.Base
local config = {
  -- If a user has a sources list it will replace this one.
  -- Only sources listed here will be loaded.
  -- You can also add an external source by adding it's name to this list.
  -- The name used here must be the same name you would use in a require() call.
  sources = {
    "filesystem",
    "git_status",
    "buffers",
    "document_symbols",
  },
  default_source = "filesystem", -- you can choose a specific source `last` here which indicates the last used source
  enable_diagnostics = false,
  enable_cursor_hijack = true, -- If enabled neotree will keep the cursor on the first letter of the filename when moving in the tree.
  hide_root_node = false, -- Hide the root node.
  retain_hidden_root_indent = false, -- IF the root node is hidden, keep the indentation anyhow.
  use_libuv_file_watcher = true,
  -- This is needed if you use expanders because they render in the indent.
  -- popup_border_style is for input and confirmation dialogs.
  -- Configurtaion of floating window is done in the individual source sections.
  -- "NC" is a special style that works well with NormalNC set
  popup_border_style = "", -- "double", "rounded", "single", "solid", (or "" to use 'winborder' on Neovim v0.11+)
  source_selector = {
    winbar = true, -- toggle to show selector on winbar
    statusline = false, -- toggle to show selector on statusline
    show_scrolled_off_parent_node = false, -- this will replace the tabs with the parent path
    -- of the top visible node when scrolled down.
    sources = {
      { source = "filesystem" },
      { source = "buffers" },
      { source = "document_symbols" },
    },
  },
  commands = {
    ["system_open"] = function(state)
      local node = state.tree:get_node()
      local path = node:get_id()
      -- macOs: open file in default application in the background.
      local sysname = vim.loop.os_uname().sysname
      if sysname == "Darwin" then
        vim.fn.jobstart({ "open", path }, { detach = true })
      elseif sysname == "Linux" then
        vim.fn.jobstart({ "xdg-open", path }, { detach = true })
      else
        vim.print("Unknown platform " .. sysname)
      end
    end,
    ["go_deep"] = open_single_child_dir_recursively,
    ["go_shallow"] = function(state)
      local node = state.tree:get_node()
      if node.type == "directory" and node:is_expanded() then
        filesystem.toggle_directory(state, node)
      else
        renderer.focus_node(state, node:get_parent_id())
      end
    end,
    ["telescope_find"] = function(state)
      local node = state.tree:get_node()
      local path = node:get_id()
      telescope.find_files(getTelescopeOpts(state, path))
    end,
    ["telescope_grep"] = function(state)
      local node = state.tree:get_node()
      local path = node:get_id()
      telescope.live_grep(getTelescopeOpts(state, path))
    end,
    ["copy_path"] = function(state)
      -- NeoTree is based on [NuiTree](https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/tree)
      -- The node is based on [NuiNode](https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/tree#nuitreenode)
      local node = state.tree:get_node()
      local filepath = node:get_id()
      local filename = node.name
      local modify = vim.fn.fnamemodify

      local results = {
        filepath,
        modify(filepath, ":."),
        modify(filepath, ":~"),
        filename,
        modify(filename, ":r"),
        modify(filename, ":e"),
      }

      vim.ui.select({
        "1. Absolute path: " .. results[1],
        "2. Path relative to CWD: " .. results[2],
        "3. Path relative to HOME: " .. results[3],
        "4. Filename: " .. results[4],
        "5. Filename without extension: " .. results[5],
        "6. Extension of the filename: " .. results[6],
      }, { prompt = "Choose to copy to clipboard:" }, function(choice)
        if choice then
          local i = tonumber(choice:sub(1, 1))
          if i then
            local result = results[i]
            vim.fn.setreg("+", result)
            vim.notify("Copied: " .. result)
          else
            vim.notify "Invalid selection"
          end
        else
          vim.notify "Selection cancelled"
        end
      end)
    end,
  }, -- A list of functions
  window = { -- see https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/popup for
    auto_expand_width = false, -- expand the window when file exceeds the window width. does not work with position = "float"

    -- position = "50%", -- 50% means center it
    follow_current_file = {
      enabled = true, -- This will find and focus the file in the active buffer every time
      --               -- the current file is changed while the tree is open.
      leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
    },
    group_empty_dirs = true, -- when true, empty folders will be grouped together
    mappings = {
      ["<space>"] = {
        "toggle_node",
        nowait = false, -- disable `nowait` if you have existing combos starting with this char that you want to use
      },
      ["<Left>"] = "go_shallow",
      ["<Right>"] = "go_deep",
      ["<cr>"] = { "open", config = { expand_nested_files = true } }, -- expand nested file takes precedence
      ["<esc>"] = "cancel", -- close preview or floating neo-tree window
      ["P"] = {
        "toggle_preview",
        config = {
          use_float = true,
          use_image_nvim = false,
          -- title = "Neo-tree Preview", -- You can define a custom title for the preview floating window.
        },
      },
      -- ["<C-f>"] = { "scroll_preview", config = {direction = -10} },
      -- ["<C-b>"] = { "scroll_preview", config = {direction = 10} },
      -- ["l"] = "focus_preview",
      ["S"] = "open_split",
      -- ["S"] = "split_with_window_picker",
      ["s"] = "noop",
      -- ["sr"] = "open_rightbelow_vs",
      -- ["sl"] = "open_leftabove_vs",
      -- ["s"] = "vsplit_with_window_picker",
      ["t"] = "noop",
      -- ["<cr>"] = "open_drop",
      -- ["t"] = "open_tab_drop",
      ["w"] = "open_with_window_picker",
      -- ["C"] = "close_node",
      ["C"] = "close_all_subnodes",
      ["z"] = "close_all_nodes",
      --["Z"] = "expand_all_nodes",
      ["W"] = "expand_all_subnodes",
      ["R"] = "refresh",
      -- ["q"] = "close_window",
      ["?"] = "show_help",
      ["<"] = "prev_source",
      [">"] = "next_source",
    },
  },
  filesystem = {
    window = {
      mappings = {
        ["o"] = "system_open",
        ["F"] = "telescope_find",
        ["f"] = "telescope_grep",
        ["s"] = "git_add_file",
        ["u"] = "git_unstage_file",
        ["a"] = {
          "add",
          -- some commands may take optional config options, see `:h neo-tree-mappings` for details
          config = {
            show_path = "relative", -- "none", "relative", "absolute"
            follow_current_file = true,
          },
        },
        ["c"] = "copy_to_clipboard", -- takes text input for destination, also accepts the config.show_path and config.insert_as options
        ["d"] = "delete",
        ["A"] = "add_directory", -- also accepts the config.show_path and config.insert_as options.
        ["m"] = "move", -- takes text input for destination, also accepts the config.show_path and config.insert_as options
        ["r"] = "rename",
        ["p"] = "paste_from_clipboard",
        ["x"] = "cut_to_clipboard",
        ["e"] = "toggle_auto_expand_width",
        ["y"] = "copy_path",
      },
    },
    filtered_items = {
      visible = false, -- when true, they will just be displayed differently than normal items
      force_visible_in_empty_folder = false, -- when true, hidden files will be shown if the root folder is otherwise empty
      show_hidden_count = false, -- when true, the number of hidden items in each folder will be shown as the last entry
      hide_dotfiles = false,
      hide_gitignored = false,
      hide_by_name = {
        ".DS_Store",
        "thumbs.db",
        ".git",
        --"node_modules",
      },
    },
  },
  document_symbols = {
    window = {
      mappings = {
        ["<Left>"] = "toggle_node",
        ["<Right>"] = "toggle_node",
      },
    },
  },
}

require("neo-tree").setup(config)
