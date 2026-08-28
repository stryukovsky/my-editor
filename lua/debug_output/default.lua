return {
  language_by_adapter = {
    java = "Java",
    ["pwa-node"] = "JavaScript / TypeScript",
    python = "Python",
    debugpy = "Python",
    go = "Go",
    codelldb = "Rust",
    scala = "Scala",
  },
  output_policy = {
    java = {
      -- Java Debug: `internalConsole` | `integratedTerminal` | `externalTerminal`
      defaults = { console = "internalConsole" },
    },
    ["pwa-node"] = {
      -- js-debug: console destination; `std` captures process stdout/stderr.
      defaults = { console = "internalConsole", outputCapture = "std" },
    },
    python = {
      -- debugpy: console destination; redirectOutput forwards stdout/stderr.
      defaults = { console = "internalConsole", redirectOutput = true },
    },
    debugpy = {
      -- `debugpy` is also used by existing launch.json templates.
      defaults = { console = "internalConsole", redirectOutput = true },
    },
    go = {
      -- Delve: `remote` emits debuggee stdout/stderr as DAP output events.
      defaults = { outputMode = "remote" },
    },
    codelldb = {
      -- CodeLLDB: `console` | `integrated` | `external`.
      defaults = { terminal = "console" },
    },
    scala = {
      -- Metals already emits debuggee output as DAP output events.
      defaults = {},
    },
  },
}
