# midword-completion Specification

## Purpose
Make completion acceptance within existing words predictable while preserving server edit intent, snippet interaction, and Unicode text around the cursor.

## Requirements

### Requirement: Identical suffixes are reused without an explicit edit range

For a plain completion without an explicit server edit range, acceptance SHALL reuse an immediately adjacent suffix when it exactly equals the untyped remainder of the candidate identifier. The final identifier SHALL appear once, with the cursor at its end. Unrelated trailing text SHALL remain intact.

#### Scenario: Complete before an identical suffix
- **WHEN** the buffer contains `pri|nt(value)`, `|` marks the cursor, and the user accepts plain candidate `print` without a server edit range
- **THEN** the buffer contains `print|(value)` without `printnt` or duplicated parentheses

#### Scenario: Complete before a whole existing candidate
- **WHEN** the buffer contains `|print(value)` and the user manually selects and accepts plain candidate `print` without a server edit range
- **THEN** the buffer contains `print|(value)` without a second `print`

#### Scenario: A different suffix is not inferred to be redundant
- **WHEN** the buffer contains `pri|Other` and the user accepts plain candidate `print` without a server edit range
- **THEN** the buffer contains `print|Other` and `Other` is not removed

### Requirement: Explicit LSP edit boundaries remain authoritative

Acceptance SHALL honor the applicable explicit LSP edit range, including insert/replace edits and inherited edit ranges. Suffix reuse SHALL NOT extend that range merely because adjacent text resembles the candidate. Text outside the applied range SHALL remain unchanged except for explicit additional edits.

#### Scenario: A text edit covers the existing suffix
- **WHEN** the buffer contains `pri|nt(value)` and the accepted item replaces the entire `print` span with `print`
- **THEN** the buffer contains `print|(value)` exactly once

#### Scenario: A text edit intentionally stops at the cursor
- **WHEN** the buffer contains `pri|nt(value)` and an explicit text edit replaces only `pri` with `print`
- **THEN** the buffer contains `print|nt(value)` because `nt` is outside that edit

#### Scenario: Insert and replace ranges differ
- **WHEN** an item supplies an insert range covering `pri` and a replace range covering `print` in `pri|nt(value)`
- **THEN** the result matches the native acceptance policy for the supported runtime: `print|nt(value)` for insertion or `print|(value)` for replacement, without an additional suffix rewrite

#### Scenario: The completion list supplies an edit range
- **WHEN** a list default supplies a full-word edit range and an item inherits it
- **THEN** acceptance produces the same text as the equivalent explicit item range

### Requirement: Snippets preserve expansion and surrounding text

Accepting a snippet inside a word SHALL apply its specified replacement span once, expand its body once, and preserve native placeholder navigation and final cursor placement. Snippet syntax SHALL NOT be treated as a plain identifier for suffix reuse.

#### Scenario: A snippet replaces a whole word
- **WHEN** the buffer contains `cal|l;`, the edit range covers `call`, and the accepted snippet body is `call(${1:value})$0`
- **THEN** the buffer contains `call(value);`, the `value` placeholder is active, and no extra `l` remains

#### Scenario: Jump to the final snippet position
- **WHEN** the user replaces that placeholder with `item` and invokes the existing forward snippet jump
- **THEN** the buffer contains `call(item)|;` with surrounding punctuation preserved

### Requirement: Unicode positions preserve complete characters

Midword acceptance SHALL convert negotiated LSP positions to valid buffer boundaries and preserve complete Unicode characters. Cyrillic identifiers and text before or after an edit SHALL remain intact. Byte offsets, LSP code units, and display widths SHALL NOT be treated as interchangeable.

#### Scenario: Reuse a Cyrillic suffix
- **WHEN** the buffer contains `при|вет()` and the user accepts plain candidate `привет` without an edit range
- **THEN** the buffer contains `привет|()` with valid UTF-8 and no repeated suffix

#### Scenario: An encoded range follows multibyte text
- **WHEN** the buffer contains `-- привет 😀` on the preceding line and `local привет = "😀"; pri|nt(value)` on the edited line, and a server using UTF-16 supplies the full `print` range
- **THEN** acceptance changes only that range, produces `print|(value)`, and preserves the Cyrillic text and emoji exactly

### Requirement: Acceptance remains isolated and reversible

Midword handling SHALL run only for an intentionally accepted eligible item in its originating buffer and context. Cancellation SHALL preserve original text. Acceptance SHALL preserve native additional edits, commands, and undo behavior; it SHALL NOT rewrite another completion source or an unrelated buffer.

#### Scenario: Cancel a selected completion
- **WHEN** the user selects a candidate in `pri|nt(value)` and cancels the popup
- **THEN** the original `print(value)` buffer text is restored with no suffix removal or acceptance side effects

#### Scenario: An accepted item also imports a symbol
- **WHEN** a midword LSP item includes an import edit and an acceptance command
- **THEN** the identifier and import are applied once and the command executes once

#### Scenario: Undo an accepted completion
- **WHEN** the user accepts a midword completion and undoes its acceptance using the native undo sequence established by the baseline fixture
- **THEN** the original prefix and suffix are restored without leftover text from suffix handling

#### Scenario: Another source owns insertion behavior
- **WHEN** completion is accepted in a terminal command buffer or a typed floating input
- **THEN** its existing source-specific acceptance behavior remains unchanged
