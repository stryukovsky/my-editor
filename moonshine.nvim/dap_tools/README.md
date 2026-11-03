# DAP tools

Use `<leader>da` to activate C/C++, Go, Java, JavaScript/TypeScript, Python,
Rust, or Scala debugging. `<leader>dd` chooses a debuggee to launch afterward.
Opening the picker and reading previews do not activate adapters.

The picker checks the current project (marked project, Git root, then cwd) for
language root identifiers, including nested manifests in mixed projects.
Nearest manifests rank first; unmatched languages follow alphabetically.
Matched identifiers and predefined debuggee configurations appear in the
preview. When several languages match, Enter activates without closing the
picker; press q or Esc when finished. Failed activation leaves it open too.
Activation lasts for the current Neovim session and preserves custom configs.

Executables are provided by the existing Mason installations. Python prefers
the installed debugpy adapter, then Mason's debugpy environment, then debugpy
in the project virtualenv/system Python. It does not install packages during
activation. Project Python is also used for debuggee execution and the matching
Python LSP settings.

`dap_tools` is the single entry point for adapter activation and predefined
debuggee configurations. Rust shares CodeLLDB with C/C++ and offers executable,
executable-with-arguments, and process-attach presets. Build the Rust executable
before launching it; activation does not start Cargo or rust-analyzer discovery.

Java and Scala can be activated before their language servers connect.
`dap_tools` reuses the jdtls and Metals transport helpers; those LSP connections
are needed when launching a debuggee. Java's implicit configuration provider is
disabled so presets come from `dap_tools`. Scala has no DAP attachment hook, and
Rust configuration autoload stays disabled.

Foundry currently uses the repository's Neotest runner, which does not support
DAP. A foundry.toml alongside Python/JS manifests does not hide those adapters.

`catalog.lua` declares supported languages, root identifiers, and launch backends.
`presets.lua` contains the debuggee presets; `env_file.lua` preserves shared
envFile handling. Every predefined configuration has cwd set to
`${workspaceFolder}` and omits the console property.
