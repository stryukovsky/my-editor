# Completion language mappings

Each `<grammar>.json` owns completion context rules for that Tree-sitter
grammar. Mappings are discovered by filename on runtimepath; no Lua language
registry edit is required. The built-in set is `lua`, `typescript`, `tsx`, `go`,
`rust`, `scala`, `java`, `python`, `c`, `cpp`, and `solidity`. TSX inherits
TypeScript; C++ inherits C. Restart Neovim after editing mappings because
resolved definitions and queries are cached.

The shared contract is
[native-completion-language.schema.json](../../../schemas/native-completion-language.schema.json).
Every JSON file points to it with `$schema` for editor validation. Actual node
names must also exist in the installed grammar; the fixture runner verifies
that.

| Field              | Meaning                                                                                       |
| ------------------ | --------------------------------------------------------------------------------------------- |
| `version`          | `1`, the mapping format version                                                               |
| `language`         | Grammar name, matching the filename, such as `go`                                             |
| `extends`          | Optional parent grammar mapping; fields replace their inherited values                        |
| `identifier_nodes` | Named nodes used to collect current-line identifier words                                     |
| `comment_nodes`    | Nodes that block both context hints and identifier collection                                 |
| `string_nodes`     | String/rune nodes that block identifiers and normally give neutral context                    |
| `expressions`      | Context category → named nodes or field-conditioned rules; the closest matching ancestor wins |
| `string_contexts`  | Context category → ancestors that permit a string context, such as an import path             |
| `keywords`         | Whole identifier components excluded from affinity scoring                                    |
| `fixtures`         | Parser examples with one `<cursor>` marker and expected results                               |

Context categories are `member`, `method`, `type`, and `import`. They select the
existing weak kind preferences; they do not filter completion candidates.
Expressions containing local syntax errors stay neutral. Ordinary call arguments
must stay neutral: do not map an entire call expression to `method`.

An expression entry can also constrain the selected AST field:

```json
{
  "member": [
    "field_access",
    { "node": "method_invocation", "field": "name", "requires": ["object"] }
  ]
}
```

The Java rule matches only a qualified method's `name` field, not its receiver
or arguments. `requires` lists fields that must be present on that node.
`unless_ancestor` lists named ancestor nodes that suppress the rule. Python uses
`{"node":"attribute", "field":"attribute", "unless_ancestor":["type"]}` so
qualified annotations can fall through to their enclosing type context. The
schema and mapping suite validate both node and field names.

The Go mapping uses `selector_expression` for both fields and methods: syntax
alone cannot distinguish those. Type identifiers and generic type positions
provide type hints; import specs permit interpreted and raw-string import paths.

Rust maps dot access to `member`, type names/generic arguments to `type`, and
`use` declarations to `import`. Associated `User::create` paths outside imports
stay neutral; the mapping does not infer whether a path denotes a module, type,
or callable. Ordinary, raw, and byte strings, characters, and documentation
comments are covered by fixtures.

Scala maps fields/methods, type names/arguments/parameters, and imports.
Fixtures cover renamed imports, Scala 3 indentation and `given` declarations.
Interpolated strings remain conservative: their text and embedded expressions
give neutral context and contribute no identifiers, just like existing
template-string rules. Rust and Scala coverage here is parser/ranking fixtures;
the optional live-server integration checks remain Lua, TypeScript, and Go.

Java supports fields, qualified method names, type positions, and
ordinary/static imports. Python supports attributes, annotations, and imports.
General Python f-strings (including embedded expressions) stay conservative and
contribute no identifiers, consistent with the other template-string mappings.

For clangd, the grammar names are `c` and `cpp`, not `clang`. C handles
dot/arrow members, type positions, and quoted/system includes. C++ inherits the
C fixtures and adds templates, namespaces, modules/header-unit imports, and raw
strings. These additions use parser/ranking fixtures; no Java/Python/clangd
live-session coverage is claimed by the optional server integration suite.

Solidity handles member access, user-defined/primitive types, mapping and array
types, and import directives (including quoted paths). Fixtures cover NatSpec,
ordinary/Unicode/hex strings, and contextual ranking. Call arguments, primitive
cast arguments, incomplete syntax, and Yul calls stay neutral. Yul strings are
excluded from identifier affinity. Solidity coverage is parser/ranking fixtures;
no live Solidity LSP session is part of the optional integration suite.

All fields except `fixtures` replace the parent's entire field when supplied.
For example, overriding `expressions` replaces that object, not just one
category. Parent fixtures are followed by child fixtures and all run against the
child parser. Inheritance cycles, invalid mapping data, and invalid identifier
queries disable that adapter with a diagnostic; other languages continue
working. Lua/TypeScript retain the former combined keyword stop list for
compatibility. Go, Rust, Scala, Java, Python, C, C++, and Solidity have their
own keyword lists.

## Parser fixtures

For example, this Go fixture checks identifiers, lexical affinity, and actual
ranking using the same captured context:

```json
{
  "name": "line affinity",
  "source": "package main\nfunc main() { var user User; _ = create<cursor> }",
  "expect": {
    "context": "unknown",
    "identifiers": ["main", "user", "User", "_", "create"],
    "affinity": { "createUser": 1, "createCat": 0 },
    "ranking": ["createUser", "createCat"]
  }
}
```

`source` is the complete parseable example, including multiline context when
needed. The runner removes the marker and calculates its row and byte offset.
`identifiers` checks the complete ordered list of identifier spans on that line;
`affinity` checks distinct shared words outside the active query; `ranking`
checks the exact order of the supplied candidate names. `context` is required;
the other expectations are optional. Include negative fixtures for comments,
strings, incomplete syntax, and ordinary call arguments, not just positive
examples.

From the configuration root:

```sh
nvim --headless -u NONE -i NONE -l tests/native_completion_languages.lua
nvim --headless -u NONE -i NONE -l tests/native_completion.lua
uv run --with pynvim python tests/native_completion_integration.py
```

The mapping suite requires every mapped grammar's parser and verifies node names
before executing its fixtures. It also checks invalid JSON, invalid context
groups, and inheritance cycles. The integration suite additionally checks the
installed Lua, TypeScript, and Go servers when their executables are available.
Adding a mapping does not install its parser or configure its LSP server.
