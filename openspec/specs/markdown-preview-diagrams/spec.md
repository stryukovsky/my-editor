# markdown-preview-diagrams Specification

## Purpose
Allow Markdown documents containing Mermaid source to be read as complete terminal previews with embedded diagrams and unchanged editable source.

## Requirements

### Requirement: Embedded Mermaid diagrams
The preview SHALL replace each complete Mermaid fenced code block with the text diagram produced by `mermaid-ascii`. Diagram whitespace and line boundaries MUST be preserved without prose reflow or table interpretation.

#### Scenario: Multiple diagrams surrounded by prose
- **WHEN** a document containing two supported Mermaid fences, headings, prose, and tables is previewed
- **THEN** both diagrams appear in their document positions and the surrounding content retains its existing rendering
- **AND** neither Mermaid source nor its fence delimiters appear for successfully converted blocks

#### Scenario: Fences use supported Markdown delimiters
- **WHEN** Mermaid blocks use backticks or tildes with matching Markdown closing fences
- **THEN** the complete blocks are recognized without including surrounding text in the converter input

#### Scenario: Literal examples and incomplete blocks
- **WHEN** Mermaid-looking text appears inside another code block or an unclosed Mermaid fence
- **THEN** it remains literal code and is not executed as a diagram

### Requirement: Nonblocking conversion with recoverable failure
Diagram conversion SHALL leave Neovim responsive. Missing executables, invalid diagrams, empty output, and converter timeouts SHALL preserve the affected source block verbatim in the preview and report a concise diagnostic without repeated notifications on unchanged refreshes.

#### Scenario: One diagram fails
- **WHEN** one diagram fails conversion while another succeeds
- **THEN** the failed block remains readable as its original fenced code and the successful diagram still renders

#### Scenario: Converter is unavailable or hangs
- **WHEN** the executable cannot be started or exceeds its configured timeout
- **THEN** the preview stays usable and shows the literal block without losing the rest of the document

### Requirement: Source preservation and preview lifecycle
Opening, refreshing, and closing a diagram preview SHALL preserve source bytes, modified state, and undo history. Refresh SHALL display results for the current source only, and source/preview navigation SHALL remain valid when diagram output changes line counts.

#### Scenario: Source changes during conversion
- **WHEN** a diagram is edited while its earlier conversion is pending
- **THEN** the older result cannot overwrite the current preview

#### Scenario: Preview closes during conversion
- **WHEN** the preview closes or its source is deleted before conversion completes
- **THEN** completion does not reopen a window, recreate the preview, or raise a buffer error

#### Scenario: Navigate beyond a diagram
- **WHEN** the user navigates to content after a rendered diagram and returns to source
- **THEN** navigation remains anchored to the corresponding document content and all source state is preserved

### Requirement: Markdown preview shortcut
In Markdown source and preview buffers, `<A-i>` SHALL toggle the complete rendered Markdown preview from any cursor position. The existing table-row inspector SHALL remain accessible through a documented separate shortcut. CSV/TSV inspection and other filetypes' diagnostics SHALL retain their existing `<A-i>` behavior.

#### Scenario: Open and return from the preview
- **WHEN** the user presses `<A-i>` on prose, a table, or Mermaid source
- **THEN** the full document preview opens including rendered diagrams
- **AND** pressing `<A-i>` in the preview returns to its source

#### Scenario: Non-Markdown inspection
- **WHEN** the user presses `<A-i>` in a CSV, TSV, or diagnostic-bearing code buffer
- **THEN** the existing row or diagnostic inspection action runs
