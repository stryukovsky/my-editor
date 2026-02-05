local aidviser = require "plugin_name"
aidviser.setup
 { model = "moonshotai/kimi-k2.5", endpoint = "https://openrouter.ai/api/v1/chat/completions", provider = "openai", credential_env_name = "OPENROUTER_API_KEY" }
