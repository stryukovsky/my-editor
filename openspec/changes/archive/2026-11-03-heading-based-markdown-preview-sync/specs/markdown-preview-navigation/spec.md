# Spec Delta

## Purpose

Keep Markdown source and rendered preview navigation aligned by document headings despite differences in wrapping and table layout.

## ADDED Requirements

### Requirement: Current section is determined by document order

The system SHALL define the active section as the last actual Markdown heading at or before the active buffer cursor, irrespective of heading level. Before the first heading, and in documents without headings, the active anchor SHALL be the document beginning. Moving backward SHALL recompute the section from the current position.

#### Scenario: Nested and backward navigation
- **WHEN** the cursor moves from a parent section into a child section and later back above that child heading
- **THEN** the child heading becomes the anchor on entry and the preceding heading becomes the anchor on return

#### Scenario: Preamble and heading-free document
- **WHEN** the cursor is before the first heading or anywhere in a document without headings
- **THEN** the document beginning is the active anchor

### Requirement: Heading identity survives preview layout changes

The system SHALL pair each source heading occurrence with its own preview position, supporting ATX and Setext headings and distinguishing identical titles. Heading-like text in fenced or indented code SHALL NOT become a navigation anchor. Preview formatting SHALL retain real headings as headings.

#### Scenario: Repeated titles after expanded content
- **WHEN** two headings have the same title and a wrapped paragraph or formatted table expands before the second occurrence
- **THEN** source and preview positions under the second occurrence resolve to that occurrence rather than the first

#### Scenario: Heading syntax and code examples
- **WHEN** the document contains ATX headings, Setext headings, and heading-like text inside fenced or indented code
- **THEN** only actual headings participate in synchronization

#### Scenario: Long heading
- **WHEN** a heading title exceeds the configured preview text width
- **THEN** it remains a heading and maps to its source occurrence even if its display wraps

### Requirement: Navigation synchronizes sections in both directions

When user navigation changes the active section in source or preview, the system SHALL move visible counterpart cursors to the beginning of the matching heading, or document beginning for the preamble anchor. Movement within the same section SHALL leave counterpart positions unchanged. Synchronization SHALL preserve focus and the initiating cursor and SHALL NOT trigger a reciprocal jump.

#### Scenario: Source drives preview
- **WHEN** the user moves the source cursor into another section
- **THEN** the preview cursor moves to that section's heading without moving the source cursor or changing focus

#### Scenario: Preview drives source
- **WHEN** the user moves the preview cursor into another section, including by a document-symbol jump
- **THEN** the source cursor moves to the matching heading without moving the preview cursor or changing focus

#### Scenario: Movement inside a section
- **WHEN** the user moves through paragraphs, blank lines, or table rows without crossing into a different heading section
- **THEN** the counterpart cursor remains at its current position

#### Scenario: Programmatic follow does not bounce
- **WHEN** synchronization moves a counterpart cursor onto a heading
- **THEN** the resulting cursor event does not move the initiating cursor back to its heading

### Requirement: Preview lifecycle uses the shared heading anchor

Opening or reopening a preview SHALL place it at the source's current section anchor. Closing from a preview SHALL restore source navigation at the preview's current anchor. Navigation while the counterpart is hidden SHALL retain the latest section for the next transition. Wiping either buffer SHALL clear pair-specific navigation state.

#### Scenario: Toggle inside a section
- **WHEN** a preview opens from the middle of a source section and later closes from the middle of another preview section
- **THEN** opening lands on the first section's preview heading and closing lands on the second section's source heading

#### Scenario: Hidden counterpart
- **WHEN** only the preview is visible and the user enters a new section before returning to the source
- **THEN** the source is restored at that section's heading

#### Scenario: Independent preview pairs
- **WHEN** two source/preview pairs exist and one pair is navigated or wiped
- **THEN** the other pair's navigation state is unaffected

### Requirement: Source edits rebuild section correspondence

After source edits refresh the preview, the system SHALL use the updated heading structure and rendered positions. With the source active, its current section SHALL determine the preview anchor. With the preview active, a surviving section SHALL remain selected despite shifted rows; if it is removed, the nearest surviving preceding heading SHALL be selected, falling back to document beginning.

#### Scenario: Content grows before the selected heading
- **WHEN** a source edit expands a table or paragraph before the selected heading
- **THEN** subsequent synchronization uses the heading's new preview position

#### Scenario: Heading is renamed or deleted
- **WHEN** the selected heading is renamed or deleted while the preview is active
- **THEN** a rename retains that heading occurrence and deletion selects the nearest surviving preceding heading or document beginning

### Requirement: Structural synchronization replaces positional navigation

Source/preview navigation SHALL use section anchors exclusively, without paragraph offsets, individual wrapped-line correspondence, column mapping, or proportional table-row navigation. Existing preview prose wrapping, table formatting, highlighting, read-only behavior, and document-symbol navigation SHALL remain available.

#### Scenario: Different positions within a table
- **WHEN** the user navigates between rendered rows of a table under one heading
- **THEN** the system performs no proportional table-row cursor mapping and preserves the table's rendered formatting
