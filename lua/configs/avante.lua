return {
  -- add any opts here
  -- for example
  providers = {
    ollama = {
      endpoint = "http://127.0.0.1:11434", -- Note that there is no /v1 at the end.
      model = "gemma3:12b",
    },
  },
  provider = "ollama",
}
