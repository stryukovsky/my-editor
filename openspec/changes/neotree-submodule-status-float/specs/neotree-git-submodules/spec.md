## ADDED Requirements

### Requirement: Ephemeral submodule status float

The Git-status submodule state view SHALL be a small focused read-only floating
window. Leaving its window or buffer, closing the window, or losing application
focus SHALL destroy the window and its scratch buffer.

#### Scenario: Leave the preview
- **WHEN** the user switches from the submodule float to another window
- **THEN** the float closes and its buffer is wiped rather than hidden

#### Scenario: Close the preview directly
- **WHEN** the user closes the float
- **THEN** its buffer and cleanup autocmds are removed

### Requirement: Compact submodule status

The summary SHALL contain three lines: `uncommitted changes inside: YES/NO`,
`HEAD in child: hash`, and `pinned in parent: hash`. Hashes SHALL use eight
characters. Missing checkout or pin values SHALL be labeled unavailable, and
unknown dirtiness SHALL NOT be represented as NO. The parent pin means parent
HEAD, not the index. A different child commit SHALL be highlighted red. The
window title SHALL distinguish a commit change, uncommitted contents, or both.

#### Scenario: New checkout already staged
- **WHEN** the checkout equals the index pin but differs from the parent HEAD pin
- **THEN** the summary still highlights the child hash as a pending commit change

#### Scenario: Matching committed pin with dirty contents
- **WHEN** the checkout matches the parent HEAD pin but has uncommitted changes
- **THEN** the summary shows YES and identifies uncommitted contents without claiming a commit change

### Requirement: Dismiss with keyboard

The float SHALL bind normal-mode `q` and Escape, using the layout-aware map
wrapper, to close the window and destroy its buffer.

#### Scenario: Dismiss the float
- **WHEN** the user presses `q` or Escape
- **THEN** the window closes and its buffer is wiped immediately
