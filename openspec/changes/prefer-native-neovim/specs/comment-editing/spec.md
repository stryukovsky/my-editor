# Spec Delta

## Purpose

Provide predictable line comment editing and TODO insertion for the configured languages while preserving keyboard layout support.

## ADDED Requirements

### Requirement: Toggle line comments
The configuration SHALL support line comment toggling for normal-mode lines, motions, and visual selections, including Solidity and shell filetypes, with Russian and English keyboard layouts.

#### Scenario: Toggle configured language comments
- **WHEN** the user toggles a line comment in Solidity or sh, bash, zsh, env, or dotenv
- **THEN** the line uses the appropriate // or # comment prefix and toggling again restores its text

#### Scenario: Toggle a selected range
- **WHEN** the user comments a visual selection or motion using either supported keyboard layout
- **THEN** the intended range is commented without modifying surrounding lines

### Requirement: Insert a TODO comment
The configuration SHALL preserve the existing TODO command that inserts a language-appropriate comment above the current line and positions the cursor after TODO: for continued editing.

#### Scenario: Insert above the current line
- **WHEN** the user invokes the TODO insertion mapping in a supported source buffer
- **THEN** a new commented TODO: line appears above the original line and the cursor is placed after its prefix

### Requirement: Preserve existing block comment access
The configuration SHALL retain existing block comment commands until a replacement preserving their required behavior is available.

#### Scenario: Native line comments are enabled
- **WHEN** the line comment migration is applied
- **THEN** blockwise comment commands remain available and existing completion and LSP behavior remain functional
