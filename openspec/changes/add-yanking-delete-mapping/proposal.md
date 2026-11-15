# Proposal

## Why

The existing `d` and `D` mappings avoid replacing copied text when deleting. There is no separate, deliberate delete command that reliably yanks the removed text.

## Changes

- Add a layout-aware uppercase `D` delete operator that accepts motions such as `Dw` and `D$`, yanking deleted text instead of using the black-hole register.
- In normal mode, `Dd` and `DD` delete the current line and yank it, with linewise behavior.
- In visual mode, `D` deletes the selection and yanks it.
- Use normal yank register and clipboard behavior: the configuration's `clipboard=unnamedplus` sends unqualified yanks to the system clipboard.
- Keep existing lowercase delete/change mappings and their clipboard-preserving behavior unchanged.

## Acceptance

- `Dd` and `DD` each delete and yank the current line in normal mode.
- `Dw` and other `D` motions delete and yank the motion's text.
- Visual `D` deletes and yanks characterwise, linewise, or blockwise selections as selected.
- Unqualified `D` deletions update the system clipboard like normal `y` with `clipboard=unnamedplus`.
- The new mappings work with the repository's Russian/English layout-aware mapper.
- Existing lowercase delete/change behavior remains unchanged.
