## Result

Implemented directly in the installed Neo-tree checkout. All 52 focused checks
passed on 2026-11-06. No lockfile edits or plugin commits were made.

## Repeatable check

From `/home/dmitry/.config/nvim/data/lazy/neo-tree.nvim`:

```sh
mkdir -p /tmp/neotree-nav-data/nvim /tmp/neotree-nav-state/nvim
NEOTREE_CONFIG_ROOT=/home/dmitry/.config/nvim \
XDG_DATA_HOME=/tmp/neotree-nav-data \
XDG_STATE_HOME=/tmp/neotree-nav-state \
nvim --headless -u NONE -i NONE -l tests/git_navigation_check.lua
```

Output: `PASS: 52 navigation/status checks`.

The check creates a disposable real Git repository and exercises:

- Default depth-first ordering, reverse traversal, wraparound, a clean anchor,
  and a directory anchor without changed descendants.
- Case-insensitive sorting, a custom comparator, field/direction sorting, and
  state comparator override.
- Untracked opt-in/opt-out, ignored and unavailable paths, empty candidates,
  missing status, and a root below the repository root.
- Initial async `no` then `all` status commands; subsequent refresh and sync
  `all` commands; disabled-option sync `normal` command.
- Individual nested untracked paths in parsed status; creation/removal followed
  by refresh; ignored descendants excluded from untracked candidates.
- Actual default `]g`/`[g` mappings in a real Neo-tree window, revealing previously
  unloaded ancestors and revealing loaded nodes after collapsing the tree.
- The config's actual layout-aware navigation wrapper and its repeat-navigation
  registration, delegating to the plugin commands.

Plugin files pass StyLua checks using the plugin's formatting configuration.
Changed config files pass Lua syntax loading. Both repositories pass
`git diff --check`; strict OpenSpec validation passes. A broader formatting
check on the existing config files reported pre-existing formatting differences;
those files were not reformatted wholesale.

## Implementation details and limits

Git enumeration now belongs to the plugin, so the config's argument-rewrite
handler was removed. The active filesystem keymap wrapper previously sorted raw
paths and bypassed the plugin; it now delegates non-conflict navigation while
retaining repeat behavior. Git-status source and conflict navigation are unchanged.

The first async phase remains tracked-only. Navigation uses the available cache;
untracked targets appear after the full phase completes. The existing initial
`status.showUntrackedFiles=no` policy is preserved. Deleted/unavailable files
remain skipped, consistent with the existing filesystem navigation behavior.

Changes are local to the installed plugin checkout and config; no publishing or
upstream push was performed.

## Submodule follow-up verification

The same check now creates a real local submodule and verifies changed checkout,
staged gitlink pin, clean state, and tracked dirtiness. Actual `]g`/`[g` keypresses
reach the module directory and continue past it. Ordinary directory bubbles and
untracked directory summaries remain excluded. All original ordering checks
still pass; the lexicographic experiment was reverted before verification.
