# Spec Delta

## Purpose

Provide a small, durable set of named file locations that can be reached from any buffer and browsed in predictable alphabetical order.

## ADDED Requirements

### Requirement: Global lowercase mark names
The system SHALL support one configuration-wide namespace of marks named `a` through `z`, with at most one destination per name, independent of the current buffer.

#### Scenario: Reassign a name in another file
- **WHEN** the user sets `p` in file B after setting `p` in file A
- **THEN** `p` refers only to the new location in file B

#### Scenario: Multiple files contribute names
- **WHEN** the user sets `m`, `n`, `o` in A, `p`, `q`, `r` in B, and `t`, `u`, `v` in C
- **THEN** all nine letters are available as distinct destinations from any of those files

### Requirement: Set marks with familiar keys
In Normal mode, `m{lowercase-letter}` SHALL create or relocate that named mark at the current cursor position. Unrelated native mark keys SHALL retain their Neovim behavior.

#### Scenario: Set an existing name
- **WHEN** the user presses `mp` on a different line
- **THEN** `p` moves to that cursor location

#### Scenario: Uppercase native mark
- **WHEN** the user presses `mA`
- **THEN** Neovim's native uppercase mark command remains available

### Requirement: Jump to a named mark across files
In Normal mode, `'{lowercase-letter}` SHALL open the mark's file if necessary and position the cursor on the marked line. Missing or inaccessible destinations SHALL produce a non-destructive notification.

#### Scenario: Jump to another file
- **WHEN** the user presses `'p` in file A and `p` belongs to file B
- **THEN** file B becomes current with the cursor on `p`'s line

#### Scenario: Missing name
- **WHEN** the user presses `'z` without a `z` mark
- **THEN** the current buffer and cursor stay unchanged and the user is notified

#### Scenario: Deleted target file
- **WHEN** a persisted mark points to a file that can no longer be opened
- **THEN** jumping does not create a replacement file or silently delete the mark, and the user is notified

### Requirement: Persistent destinations
Marks SHALL survive Neovim restarts and buffer closure, keeping their assigned filenames and line/column positions; edits in a loaded buffer SHALL update the mark's tracked position before it is persisted.

#### Scenario: Restart and jump
- **WHEN** the user sets `p` in file B, exits Neovim, restarts, opens file A, and presses `'p`
- **THEN** the user reaches the saved position in file B

#### Scenario: Buffer edits
- **WHEN** lines are inserted above a marked line while its file is loaded and the user later jumps to that mark
- **THEN** the jump follows the marked line rather than the obsolete line number

#### Scenario: Saved position outside changed file
- **WHEN** the target file has fewer lines than a saved mark position after an external edit
- **THEN** the jump is clamped to a valid position and does not error

### Requirement: Alphabetical traversal and repeat
`]m` and `[m` SHALL move to the next and previous assigned lowercase name in alphabetical order, wrapping at either end, regardless of file location; traversal SHALL support counts and register both directions with the shared navigation-repeat mechanism. `]]`/`[[` SHALL repeat the most recent navigation forward/backward.

#### Scenario: Forward traversal across files
- **WHEN** the names `m`, `n`, `o` in A, `p`, `q`, `r` in B, and `t`, `u`, `v` in C exist and the cursor is at `o`, and the user presses `]m`
- **THEN** the user lands on `p` in B

#### Scenario: Wrap and skip missing letters
- **WHEN** `v` is the last assigned name and the user presses `]m` from `v`
- **THEN** the user lands on `m`, skipping unassigned letters

#### Scenario: Starting away from any mark
- **WHEN** the user presses `]m` without a current traversal name
- **THEN** navigation begins at the first assigned name; `[m` begins at the last assigned name

#### Scenario: Repeat after navigation
- **WHEN** the user presses `[m` and then `[[`, `;`, or `n`
- **THEN** each repeat navigates to the next alphabetical name in the forward direction, while configured reverse-repeat keys navigate backward

#### Scenario: Count
- **WHEN** the user presses `3]m` with at least one mark defined
- **THEN** traversal advances three assigned names, wrapping as needed

#### Scenario: Empty mark set
- **WHEN** no marks exist and the user presses `]m` or `[m`
- **THEN** the current buffer and cursor remain unchanged and the user is notified

### Requirement: Visible marks in the status column
For ordinary editable file buffers, each assigned mark SHALL display its letter at the marked line within the existing status-column sign area without removing existing fold, number, diff, or other signs.

#### Scenario: Mark shown after file reopening
- **WHEN** a file with a persisted mark is reopened
- **THEN** the mark letter is visible on its marked line in the status column

#### Scenario: Mark moved or deleted
- **WHEN** a mark is moved to another line or deleted
- **THEN** the old line no longer displays that letter and the new line displays it only if the mark still exists

### Requirement: Explicit mark deletion
The user SHALL be able to remove a named lowercase mark, marks on the current line, or all marks in the current file; deleting a mark SHALL update persistent storage and visible markers.

#### Scenario: Delete one name
- **WHEN** the user invokes the named-mark deletion action for `p`
- **THEN** only `p` is removed, including its status-column display and future jump target

#### Scenario: Delete current line and file marks
- **WHEN** the user invokes `dm` on a marked line or `<leader>dm` in a file with multiple marks
- **THEN** `dm` removes the marks on that line, while `<leader>dm` removes the marks belonging to that file
