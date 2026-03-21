# Periodic Git Fetch

This module implements periodic git fetch functionality for Neovim that automatically fetches updates from remote repositories at regular intervals.

## Features

- Automatic git fetch every 10 minutes when successful
- Progressive backoff strategy on failures (5s, 15s, 30s, 1m, 2m, 5m, 10m, 30m)
- Safety checks to prevent interference with ongoing Git operations
- Internet connectivity verification
- Manual control commands

## Safety Checks

Before performing any fetch operation, the module checks for:

1. Active rebase operations (rebase-merge or rebase-apply directories)
2. Active merge operations (MERGE_HEAD file)
3. Active cherry-pick operations (CHERRY_PICK_HEAD file)
4. Active revert operations (REVERT_HEAD file)
5. Active bisect operations (BISECT_LOG file)

## Commands

- `<leader>gpf` - Start periodic fetch
- `<leader>gpt` - Stop periodic fetch
- `<leader>gpm` - Show periodic fetch status

## Configuration

The module is automatically loaded and started when Neovim starts. It will perform an initial fetch after 5 seconds and then continue with the periodic schedule.

## Implementation Details

- Uses `vim.loop.new_timer()` for efficient scheduling
- Properly handles timer lifecycle (start/stop/close)
- Provides visual feedback through print statements
- Respects Git repository state to avoid conflicts