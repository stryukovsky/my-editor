# Spec Delta

## Purpose

Enable users to copy filesystem entries in one Neovim process and paste them repeatedly in other processes using a persistent shared clipboard.

## ADDED Requirements

### Requirement: Copy replaces the shared selection
Neo-tree filesystem copy SHALL persist absolute source paths for the current entry or visual selection. Each valid copy action SHALL replace the entire previous shared selection, including when copying the same entry again. Directories SHALL be supported. Invalid or empty selections SHALL leave saved state unchanged.

#### Scenario: Replace a previous copy
- **WHEN** the user copies A and then copies B in any process
- **THEN** the shared selection contains only B

#### Scenario: Visual copy
- **WHEN** the user copies a visual selection containing files and directories
- **THEN** the shared selection contains all selected filesystem paths as one replacement batch

#### Scenario: Copy the same entry again
- **WHEN** the user copies the same entry twice
- **THEN** the entry remains saved rather than being toggled off

#### Scenario: No valid entry
- **WHEN** copy is invoked on a message node or empty selection
- **THEN** the saved selection is unchanged

### Requirement: Paste reads shared state across processes
Filesystem paste SHALL read the latest saved selection at invocation and copy its sources into the destination resolved by Neo-tree. Processes already running and newly started processes SHALL observe the same saved selection, independent of their working directory. A stale local copy selection SHALL NOT override newer saved paths.

#### Scenario: Paste in an already running process
- **WHEN** process A copies a file and already running process B pastes in another directory
- **THEN** B copies that file into its destination and leaves the source intact

#### Scenario: Persistence after exit
- **WHEN** the copying process exits and a new process pastes
- **THEN** the new process can paste the saved sources

#### Scenario: Newer copy supersedes local memory
- **WHEN** A copies one file, B copies another, and A pastes
- **THEN** A pastes the file most recently saved by B

### Requirement: Saved copies survive paste and cancellation
Paste SHALL NOT clear or rewrite the shared state, whether it succeeds, fails, or is cancelled. Esc, local clipboard clearing, cut actions, path-text yanks, and process exit SHALL NOT modify it. Only a new valid file-copy action SHALL replace the shared selection.

#### Scenario: Repeated paste
- **WHEN** the user pastes saved paths into two different destination directories
- **THEN** both destinations receive copies and the state file remains unchanged

#### Scenario: Cancellation and failure
- **WHEN** a paste is cancelled or fails, or the user presses Esc
- **THEN** the saved paths remain available to a later paste

### Requirement: Preserve local cut behavior
An active local cut selection SHALL take precedence for paste and use Neo-tree's move behavior without changing shared copy state. After the cut is consumed or cleared, subsequent paste SHALL use the saved copy selection. Text-path copying SHALL remain separate from file copying.

#### Scenario: Local cut with saved copies
- **WHEN** shared copy A exists and the user cuts B locally and pastes
- **THEN** B is moved and shared copy A remains available for subsequent paste

### Requirement: Safe storage and paste errors
Readers SHALL observe complete saved selections during concurrent copies; the last successfully published copy SHALL win. Missing or empty shared state SHALL report nothing to paste. Unreadable, malformed, or unsupported state SHALL report an error without copying stale local paths. Missing sources SHALL be reported without erasing saved paths. Storage failures SHALL be reported without claiming a successful shared copy.

#### Scenario: Concurrent copies
- **WHEN** two processes publish new copy selections concurrently
- **THEN** readers see one complete selection and never a partial or merged write

#### Scenario: Invalid saved state
- **WHEN** paste encounters malformed or unreadable state
- **THEN** it reports the problem and performs no shared paste

#### Scenario: Missing state
- **WHEN** paste has no local cut and no saved paths
- **THEN** it reports nothing to paste and creates no files

#### Scenario: A source was deleted
- **WHEN** a saved source no longer exists
- **THEN** paste reports the missing source, can continue with valid sources, and preserves the saved selection

#### Scenario: Cannot publish copy
- **WHEN** a valid copy cannot be written to shared storage
- **THEN** the user is told that saving failed and any previously published selection remains intact

### Requirement: Retain native paste interaction
The existing filesystem copy and paste keys SHALL invoke shared clipboard behavior in normal and visual copy modes. Paste SHALL retain Neo-tree's destination resolution, collision prompts, recursive directory copying, and destination refresh behavior.

#### Scenario: Destination collision
- **WHEN** a saved source has the same name as an existing destination entry
- **THEN** Neo-tree's normal conflict interaction is used and the saved selection is retained
