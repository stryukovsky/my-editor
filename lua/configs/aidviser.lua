---@diagnostic disable: missing-fields
local aidviser = require "plugin_name"
-- aidviser.setup
--  { model = "moonshotai/kimi-k2.5", endpoint = "https://openrouter.ai/api/v1/chat/completions", provider = "openai", credential_env_name = "OPENROUTER_API_KEY" }

aidviser.setup {
  model = "Qwen/Qwen2.5-Coder-7B-Instruct-AWQ",
  endpoint = "http://localhost:8000/v1/chat/completions",
  provider = "openai",
  credential_env_name = "",
}
