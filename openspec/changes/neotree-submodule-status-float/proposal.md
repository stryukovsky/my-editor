## Why

Enter on a changed submodule in Git status should explain the commit pin and
staging state in a small temporary view instead of trying to open a directory.
The existing submodule inspection specification is not implemented in this checkout.

## What Changes

- Intercept Git-status `open` for gitlinks identified from the parent index/HEAD.
- Show three summary lines: child dirtiness, short child HEAD, and short committed parent pin.
- Highlight a differing child hash red and identify commit/content changes in the title.
- Use a focused read-only float destroyed with its buffer on any leave, `q`, or Escape.
- Include submodule status despite submodule ignore settings, without editing Git configuration.

## Capabilities

### Modified Capabilities

- `neotree-git-submodules`: add an ephemeral floating presentation and pin marker.

## Impact

Implementation lives in the installed Neo-tree checkout's Git-status source.
Ordinary files and grouping directories retain their existing open behavior;
filesystem navigation is unchanged. No repository writes occur during inspection.
