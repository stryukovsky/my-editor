local M = {}

-- Entries describe supported adapters, not adapters eagerly installed into nvim-dap.
M.entries = {
  {
    id = "cpp",
    name = "C / C++",
    adapter = "codelldb",
    command = "codelldb",
    filetypes = { "c", "cpp" },
    markers = {
      "CMakeLists.txt",
      "Makefile",
      "meson.build",
      "compile_commands.json",
      ".clangd",
    },
  },
  {
    id = "go",
    name = "Go",
    adapter = "go",
    command = "dlv",
    filetypes = { "go" },
    markers = { "go.mod", "go.work" },
  },
  {
    id = "java",
    name = "Java",
    adapter = "java",
    backend = "jdtls",
    filetypes = { "java" },
    markers = {
      "pom.xml",
      "build.gradle",
      "build.gradle.kts",
      "gradlew",
      "mvnw",
      ".project",
    },
  },
  {
    id = "javascript",
    name = "JavaScript / TypeScript",
    adapter = "pwa-node",
    command = "js-debug-adapter",
    filetypes = {
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
    },
    markers = {
      "package.json",
      "jsconfig.json",
      "tsconfig.json",
      "deno.json",
      "deno.jsonc",
      "bun.lock",
      "bun.lockb",
    },
  },
  {
    id = "python",
    name = "Python",
    adapter = "python",
    filetypes = { "python" },
    markers = {
      "pyproject.toml",
      "setup.py",
      "setup.cfg",
      "requirements.txt",
      "Pipfile",
      "poetry.lock",
      "uv.lock",
      ".python-version",
      "pyvenv.cfg",
    },
  },
  {
    id = "rust",
    name = "Rust",
    adapter = "codelldb",
    command = "codelldb",
    filetypes = { "rust" },
    markers = { "Cargo.toml", "rust-project.json" },
  },
  {
    id = "scala",
    name = "Scala",
    adapter = "scala",
    backend = "Metals",
    filetypes = { "scala", "sbt" },
    markers = {
      "build.sbt",
      "build.sc",
      "build.scala",
      "build.mill",
      "scala-cli.conf",
    },
  },
}

function M.get(id)
  for _, entry in ipairs(M.entries) do
    if entry.id == id then
      return entry
    end
  end
  error("Unknown DAP language: " .. tostring(id))
end

-- No registration or prompts: safe to call from Telescope previews.
function M.configurations(entry)
  local presets = require "dap_tools.presets"
  local result = {}
  for _, ft in ipairs(entry.filetypes) do
    local preset = entry.id == "javascript"
        and (ft:find("typescript", 1, true) and "typescript" or "javascript")
      or entry.id
    result[ft] = presets[preset] and presets[preset]() or {}
  end
  return result
end

return M
