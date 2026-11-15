## ADDED Requirements

### Requirement: Keep Git-status tree shape across refreshes

The Git-status source SHALL initially show its section roots and folders
expanded. On subsequent status refreshes, it SHALL preserve the expansion
state of surviving folders in each section, including folders the user closed.
It SHALL NOT reopen closed folders solely because a file or folder was staged
or unstaged.

#### Scenario: Stage from a partly collapsed tree
- **WHEN** a file or folder is staged while other folders are open or closed
- **THEN** surviving folders retain their expansion state
- **AND** the staged entry appears under Staged where Git reports it

#### Scenario: Refresh without staging
- **WHEN** Git status refreshes after the user closes a folder
- **THEN** that folder remains closed

### Requirement: Advance after a moved entry

When staging or unstaging removes the selected Git-status entry from its
section, the source SHALL select the next surviving visible entry in display
order, preferring a sibling. At the end, it SHALL fall back to the nearest
prior visible entry. It SHALL NOT expand closed folders just to choose a
successor. If the selected entry still exists in its original section, the
source SHALL keep it selected.

#### Scenario: Stage an entry with a following sibling
- **WHEN** the selected file or folder moves to the other section and a later visible sibling remains
- **THEN** the sibling becomes selected without reopening other folders

#### Scenario: Stage the last visible entry
- **WHEN** the selected entry moves and no later visible entry survives
- **THEN** the nearest earlier visible entry becomes selected

#### Scenario: Unstage an entry
- **WHEN** the selected staged entry moves to Unstaged
- **THEN** selection advances within the staged section when possible
- **AND** the previous expansion states remain intact
