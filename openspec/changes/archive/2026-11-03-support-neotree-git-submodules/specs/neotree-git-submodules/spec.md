# Spec Delta

## Purpose

Allow users to identify and inspect Git submodule changes accurately in Neo-tree's Git status view while preserving normal filesystem navigation.

## ADDED Requirements

### Requirement: Open submodule state from Git status

In the Git status source, `<CR>` on a submodule SHALL open a read-only state view identifying the submodule and selected section. It MUST NOT open or expand the submodule directory or modify repository state.

#### Scenario: Inspect an unstaged submodule
- **WHEN** the user presses `<CR>` on a submodule in Unstaged
- **THEN** its Git state view opens with the submodule path and Unstaged context
- **AND** no directory is opened and no Git state is changed

#### Scenario: Inspect a staged submodule
- **WHEN** the user presses `<CR>` on a submodule in Staged
- **THEN** its state view opens with Staged context and the recorded commit transition

### Requirement: Show distinct recorded and checked-out commits

The state view SHALL separately label full commit hashes recorded by the superproject HEAD, recorded in the index, and checked out in the submodule. It SHALL distinguish a changed checkout commit, tracked dirtiness, and untracked dirtiness. Each open SHALL collect current state rather than reuse stale displayed metadata.

#### Scenario: Three different commits
- **WHEN** HEAD records commit A, the index records B, and the submodule checkout is at C
- **THEN** inspection labels all three full hashes distinctly
- **AND** staged context identifies A to B and unstaged context identifies B to C

#### Scenario: Dirty content without a commit change
- **WHEN** all three hashes match but tracked or untracked child content has changed
- **THEN** inspection shows matching hashes and the corresponding dirty flags without claiming a pointer change

#### Scenario: Reopen after external checkout
- **WHEN** the submodule checkout changes after the tree was rendered and the user opens its state
- **THEN** the checked-out hash reflects the current checkout

### Requirement: Detect and group submodule changes accurately

The Git status source SHALL show staged gitlink changes in Staged and worktree gitlink changes or tracked/untracked submodule dirtiness in Unstaged. It SHALL show both entries when both apply, preserve conflict status, and omit clean submodules. Detection SHALL expose these changes even when submodule ignore settings would hide them.

#### Scenario: Changed checkout commit only
- **WHEN** a submodule checks out a commit different from the unchanged index gitlink
- **THEN** it appears in Unstaged and not in Staged

#### Scenario: Tracked dirty only
- **WHEN** the submodule has tracked modifications but no staged gitlink change
- **THEN** it appears in Unstaged and inspection identifies tracked dirtiness

#### Scenario: Untracked dirty only
- **WHEN** the submodule contains untracked content but no staged gitlink change
- **THEN** it appears in Unstaged and inspection identifies untracked dirtiness

#### Scenario: Staged pointer plus further worktree changes
- **WHEN** a gitlink change is staged and the child checkout then changes commit or becomes dirty
- **THEN** the submodule appears in both sections with the appropriate context

#### Scenario: Staged pointer only
- **WHEN** the index records a changed gitlink and the child checkout matches it with no dirty content
- **THEN** the submodule appears in Staged and not in Unstaged

#### Scenario: Clean submodule
- **WHEN** the recorded and checked-out commits match and no tracked or untracked child content is dirty
- **THEN** no changed-submodule entry appears

#### Scenario: Ignore settings hide child dirtiness from default Git status
- **WHEN** submodule ignore settings would suppress tracked or untracked dirtiness
- **THEN** this Git status source still reports the dirtiness without changing Git configuration

### Requirement: Handle unavailable and conflicted submodules honestly

Submodule inspection SHALL identify unavailable or inapplicable values explicitly for missing, uninitialized, added, deleted, or conflicted gitlinks. It MUST NOT substitute the superproject HEAD for a missing child HEAD. Read failures SHALL be reported rather than represented as clean state.

#### Scenario: Uninitialized checkout
- **WHEN** a displayed submodule has no initialized child repository
- **THEN** inspection shows available recorded gitlink hashes and labels the checked-out hash unavailable without opening a folder

#### Scenario: Added or deleted gitlink
- **WHEN** the selected submodule is added or deleted relative to HEAD or the index
- **THEN** inspection labels absent sides explicitly and shows the available hashes

#### Scenario: Conflicted gitlink
- **WHEN** the submodule has an unresolved gitlink conflict
- **THEN** it remains a conflict in Unstaged and inspection labels the available conflict-stage hashes
- **AND** it does not claim there is a resolved single index commit

#### Scenario: Git read fails
- **WHEN** the repository becomes unreadable during state collection
- **THEN** the user sees a read error and no fabricated clean result or directory opening

### Requirement: Preserve source boundaries and refresh behavior

Filesystem-source `<CR>` SHALL retain normal directory navigation for submodules. Ordinary Git status files and section directories SHALL retain their current opening and navigation behavior. Explicit Git status refresh SHALL recollect submodule state and remove resolved rows while preserving ordinary-file statuses and paths.

#### Scenario: Filesystem submodule navigation
- **WHEN** the user presses `<CR>` on a submodule directory in the filesystem source
- **THEN** it follows normal filesystem directory navigation rather than opening the Git state view

#### Scenario: Ordinary Git status entries
- **WHEN** the user opens an ordinary changed file or navigates a grouping directory in Git status
- **THEN** the existing file-open or directory-navigation action runs

#### Scenario: Refresh after child changes
- **WHEN** submodule changes are introduced or resolved externally and Git status is explicitly refreshed
- **THEN** rows and group placement reflect the current submodule state, including removal of now-clean entries

#### Scenario: Ordinary paths remain intact
- **WHEN** refreshed status includes ordinary renamed, conflicted, or untracked files with spaces or newlines in their names
- **THEN** their paths, statuses, and group placement remain correct
