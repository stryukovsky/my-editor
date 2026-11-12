## MODIFIED Requirements

### Requirement: Rename the selection
`r` SHALL prompt for a new name, rename the selection, and leave the selection on the renamed entry. In Neo-tree's filesystem source, this action SHALL request supported LSP file-rename edits before the filesystem rename and notify supporting servers after success. With no supporting server, it SHALL perform the ordinary rename.

#### Scenario: Rename a file
- **WHEN** the user presses `r` on `a.txt` and submits `b.txt`
- **THEN** `a.txt` is renamed to `b.txt` and `b.txt` is selected

#### Scenario: Cancel rename
- **WHEN** the user presses `r` and cancels the prompt
- **THEN** the name is unchanged
- **AND** no LSP file-rename request or notification is sent

#### Scenario: Update references through a supporting server
- **WHEN** filesystem `r` renames a file matched by an active server's file-rename capability
- **THEN** returned pre-rename workspace edits are applied before the filesystem rename
- **AND** each applicable rename method is dispatched once per selected supporting client
- **AND** post-rename notifications are sent only after filesystem success

#### Scenario: One connected client
- **WHEN** filesystem `r` is invoked with exactly one connected LSP client for the selected path's project
- **THEN** the rename prompt opens without a client picker
- **AND** that client is the only possible recipient of supported rename methods

#### Scenario: Multiple connected clients
- **WHEN** filesystem `r` is invoked with two or more connected LSP clients for the selected path's project
- **THEN** a picker allows selecting multiple client instances before the rename prompt
- **AND** only the selected clients receive applicable rename methods

#### Scenario: Cancel client selection
- **WHEN** the user cancels the LSP recipient picker
- **THEN** no rename prompt opens and no disk rename or LSP rename operation occurs

#### Scenario: No supporting server
- **WHEN** filesystem `r` renames an entry with no active matching file-rename provider
- **THEN** the ordinary filesystem rename, buffer handling, refresh, and selection still run
- **AND** no unsupported LSP rename method is sent

#### Scenario: Destination exists or name is unchanged
- **WHEN** the submitted destination already exists or resolves to the source path
- **THEN** Neo-tree refuses the operation before requesting LSP edits
- **AND** existing destination contents remain intact

#### Scenario: Filesystem failure
- **WHEN** the filesystem rename fails after pre-rename processing
- **THEN** the failure is reported and no successful rename notification is sent
- **AND** the tree does not claim that the destination was successfully renamed

#### Scenario: Rename a directory with modified buffers
- **WHEN** filesystem `r` successfully renames a directory containing open modified files
- **THEN** Neo-tree preserves those unsaved contents and updates their buffer paths
- **AND** LSP assistance follows the server's directory filters

## ADDED Requirements

### Requirement: Explicitly scoped LSP file rename
LSP file-rename assistance SHALL be enabled explicitly through Neo-tree's filesystem `r` configuration. Enabling it MUST NOT install global mappings, automatic file-operation subscriptions, wildcard LSP capability overrides, or replace unrelated rename actions.

#### Scenario: Other actions retain their behavior
- **WHEN** the integration is configured and the user invokes `<leader>rn`, document-symbol rename, Oil operations, or cut/paste moves
- **THEN** those actions retain their existing handlers
- **AND** the new filesystem `r` integration does not intercept them

#### Scenario: Startup and repeated use
- **WHEN** Neovim starts and the user opens Neo-tree repeatedly
- **THEN** no automatic LSP file-operation event subscribers or global rename mappings are added
- **AND** invoking filesystem `r` still uses the explicit configured integration

#### Scenario: Server capability negotiation
- **WHEN** an explicitly selected supporting language server starts
- **THEN** its client configuration advertises the supported file-rename interactions before initialization
- **AND** unrelated server configurations and global LSP defaults remain unchanged
