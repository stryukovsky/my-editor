## Implementation

- [x] Identify exact gitlinks from index/HEAD and collect fresh checkout, staging, and dirty state with bounded read-only Git commands.
- [x] Intercept Git-status opening for submodules while preserving ordinary opening.
- [x] Render compact short hashes and highlight a changed child hash red in a focused scratch float.
- [x] Destroy float, buffer, and cleanup autocmds on leave/close/focus loss.
- [x] Expose submodule changes despite ignore settings in Git-status collection.

## Verification

- [x] Extend the disposable real-submodule fixture to verify staged pins, checkout comparison, dirty matching pins, and unavailable checkouts.
- [x] Exercise actual Enter in Git status, inspect read-only float content/highlight, and verify buffer destruction on leaving and direct closing.
- [x] Run the combined navigation/inspection check, plugin formatting checks, diff checks, and strict OpenSpec validation.

## Compact view follow-up

- [x] Replace the verbose body with three requested summary lines and eight-character hashes.
- [x] Label commit versus uncommitted-content changes in the title.
- [x] Add layout-aware `q` and Escape bindings and verify both destroy the window and buffer.
- [x] Run the expanded check: 76 assertions pass, including short hashes and YES/NO contents.
