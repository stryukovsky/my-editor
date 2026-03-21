# Periodic Git Fetch

This module implements periodic git fetch functionality for Neovim that automatically fetches updates from remote repositories at regular intervals using NeoGit's built-in fetch functionality.

## Features

- Automatic git fetch every 10 minutes when successful
- Progressive backoff strategy on failures (5s, 15s, 30s, 1m, 2m, 5m, 10m, 30m)
- Safety checks using NeoGit's repository state to prevent interference with ongoing Git operations
- Internet connectivity verification
- Manual control commands

## Safety Checks

Before performing any fetch operation, the module checks NeoGit's repository state for:

1. Active rebase operations (rebase.head)
2. Active merge operations (merge.head)
3. Active cherry-pick or revert operations (sequencer.head)
4. Active bisect operations (bisect state)

## Commands

- `<leader>gpf` - Start periodic fetch
- `<leader>gpt` - Stop periodic fetch
- `<leader>gpm` - Show periodic fetch status

## Configuration

The module is automatically loaded and started when Neovim starts. It will perform an initial fetch after 5 seconds and then continue with the periodic schedule.

## Implementation Details

- Uses `vim.loop.new_timer()` for efficient scheduling
- Leverages NeoGit's `git.fetch.fetch()` function for actual fetch operations
- Uses NeoGit's repository state checking for operation safety
- Properly handles timer lifecycle (start/stop/close)
- Provides visual feedback through print statements
- Respects Git repository state to avoid conflicts

## Benefits of NeoGit Integration

- Uses the same fetch implementation as NeoGit's UI
- Leverages NeoGit's robust repository state management
- Integrates seamlessly with NeoGit's error handling
- Benefits from NeoGit's authentication handling