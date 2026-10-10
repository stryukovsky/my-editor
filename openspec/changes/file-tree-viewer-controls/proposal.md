# Proposal

## Why

Neo-tree and Ranger both browse the filesystem, but their controls only partly match. The same action already uses the same key in some cases (`f`, `F`, `a`, `r`, `x`, `oo`, `O`) and a different key or a different meaning in others (`d`/`dd`, `l`/`L`, `<A-,>`/`<A-.>`). A single file-tree standard makes Neo-tree the reference and gives Ranger a map to follow.

## What Changes

- Add a viewer-agnostic file-tree standard: named actions, canonical keys, and the behavior each action must have on a filesystem tree.
- Treat the current Neo-tree filesystem source (`lua/configs/neotree.lua`) as the reference implementation. Do not redesign its keys.
- Bring Ranger (`~/.config/ranger`) onto that standard: same action, same key, except where a host cannot perform the action.
- Split actions into three groups so Ranger is not required to imitate Neovim:
  - **Shared** — both Neo-tree and Ranger must implement them.
  - **Tree-shape** — expand, collapse, and source switching. Neo-tree only; Ranger uses miller columns and has no sources.
  - **Host extensions** — editor or file-manager features that must not occupy a canonical shared key (Neovim git/search/replace, Ranger archives).
- Leave Neo-tree buffers and document-symbols sources unchanged. They are not part of the file-tree standard.

Assumptions:

- Canonical keys are the bindings already configured for the Neo-tree filesystem source, plus Neo-tree defaults that this config does not override and that are part of daily tree use (`j`/`k`, `T` trash, `q` close, `?` help).
- Ranger config lives at `~/.config/ranger`, outside this git repo. Implementation edits that file; this change only specifies the contract.
- `h` / `l` / Enter mean the same *actions* in both hosts (ascend, descend-or-open). Ranger renders them as miller-column movement; Neo-tree renders them as expand, collapse, and open.
- Ranger-only archive commands (`zip`, `unzip`) stay, on keys that are not canonical shared keys.

## Capabilities

### New Capabilities

- `file-tree-viewer`: Filesystem tree actions and canonical keys shared by Neo-tree and Ranger, plus the host-only actions that must not collide with that map.

### Modified Capabilities

- None. The project has no existing specs.

## Impact

- Spec and design live in this repo under `openspec/changes/file-tree-viewer-controls/`.
- Reference config: `lua/configs/neotree.lua`, `lua/utils/neotree_utils.lua` (`go_deep` / `go_shallow`), filesystem toggle in `lua/mappings/ui-components.lua` (`<A-e>`).
- Ranger implementation target: `~/.config/ranger/rc.conf` and `~/.config/ranger/commands.py`.
- Neo-tree buffers (`<A-b>`) and document symbols (`<A-l>`) stay out of scope.
- Oil.nvim stays out of scope. Its `<A-e>`, `<A-l>`, `<A-b>` no-ops remain as they are.
