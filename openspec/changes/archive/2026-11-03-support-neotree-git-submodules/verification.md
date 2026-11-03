# Verification

Implemented directly in the user-owned fork at `data/lazy/neo-tree.nvim`, as requested. The only runtime config change removes the obsolete `moonshine.neotree.git_groups` loader replacement. The extracted local module itself and unrelated in-progress config migration are untouched. No dependency pins changed; the fork changes are uncommitted and have not been pushed.

## Automated proof

The fork's Plenary suite uses disposable local Git repositories and a real Neo-tree renderer. Focused commands run from `/home/dmitry/.config/nvim`:

```sh
XDG_DATA_HOME=/tmp/neotree-test-data XDG_STATE_HOME=/tmp/neotree-test-state XDG_CACHE_HOME=/tmp/neotree-test-cache \
  nvim --headless --noplugin -u /tmp/neotree-submodule-init.lua \
  -c "lua require('plenary.test_harness').test_directory('data/lazy/neo-tree.nvim/tests/neo-tree/sources/submodules_spec.lua', {minimal_init='/tmp/neotree-submodule-init.lua'})"

XDG_DATA_HOME=/tmp/neotree-test-data XDG_STATE_HOME=/tmp/neotree-test-state XDG_CACHE_HOME=/tmp/neotree-test-cache \
  nvim --headless --noplugin -u /tmp/neotree-submodule-init.lua \
  -c "lua require('plenary.test_harness').test_directory('data/lazy/neo-tree.nvim/tests/neo-tree/sources/git_status_spec.lua', {minimal_init='/tmp/neotree-submodule-init.lua'})"
```

The temporary minimal init prepends the installed fork to runtimepath, appends installed `nui.nvim` and `plenary.nvim`, sets `NEOTREE_TESTING=true`, and sources the fork's `plugin/neo-tree.lua`. It avoids starting the full personal configuration. These tests also run with the fork's normal dependency-based test setup.

Results: **4/4 new submodule tests and 1/1 existing status integration test passed**.

## Status matrix

Fixtures read actual `git status --porcelain=v2 -z --untracked-files=all --ignore-submodules=none`. Important observed record prefixes and expected sections:

| State | XY / submodule field | Sections / result |
| --- | --- | --- |
| Clean | no record | Neither section |
| Changed checkout commit | `.M SC..` | Unstaged |
| Tracked modifications only | `.M S.M.` | Unstaged; tracked flag true |
| Untracked content only | `.M S..U` | Unstaged; untracked flag true |
| Staged gitlink, checkout matches | `M. S...` | Staged |
| Staged gitlink plus further checkout | `MM SC..` | Both, each as a leaf |
| Deleted gitlink | `D.` with HEAD mode `160000` | Staged; absent index hash |
| Unmerged gitlink | `u UU` with gitlink stage modes | Conflict; base/ours/theirs hashes |

The ignore fixture sets `submodule.module space.ignore=all`; the source still reports child dirtiness without changing this setting. Names with spaces and newlines survive parsing. A synthetic rename record also uses 64-character object IDs to prove the parser does not depend on SHA-1 field widths.

## Inspection and compatibility

- A three-commit fixture asserts separately labeled full HEAD/index/checkout hashes, and unchanged raw status before/after collection proves inspection does not mutate Git state.
- The actual Git status `open` command opens a `nofile`, readonly, nonmodifiable buffer containing the checkout hash rather than a directory.
- Uninitialized checkout collection shows the parent's recorded hash and an unavailable child hash; it never substitutes the parent repository HEAD. Added and deleted gitlinks label absent sides. Unmerged index entries label each available conflict stage. Collection fails explicitly when the repository is removed.
- Returning the checkout and index to the original commit, invoking `items.get_git_status(state)`, and waiting for the real renderer removes both rows. Reopening collection returns the current checkout hash. The user-facing refresh action is `:Neotree git_status`.
- A separate UI integration test opens an ordinary changed file using the Git status command, then switches to filesystem and expands the submodule to show its tracked file. Filesystem commands are unchanged.
- The existing integration test covers partial staging, ordinary deletion/untracked entries, renamed and edited files, queued index writes, unborn repositories, external index/commit refresh, and scans completing after the panel closes.

## Scope checks

Fork Lua changes were formatted with its own StyLua configuration. Fork and scoped config/OpenSpec whitespace checks pass. Strict OpenSpec validation passes. The fork README describes inspection, explicit ignore-setting override, and refresh behavior. No new key mappings were introduced.

These are headless integration checks; no manual GUI session was used. Publish the fork changes separately before relying on a fresh plugin installation to contain them.
