---@diagnostic disable-next-line: missing-fields
require("nvim-treesitter").setup {
  auto_install = true,
  install_dir = vim.fn.stdpath "data" .. "/treesitter",
  ensure_installed = {
    -- ===== General-Purpose & Systems Programming =====
    "c", -- C language
    "cpp", -- C++
    "rust", -- Rust
    "zig", -- Zig

    -- ===== JVM Ecosystem (as requested) =====
    "java",
    "kotlin",
    "scala",
    "clojure", -- JVM functional language

    -- ===== Web & Scripting =====
    "javascript",
    "typescript", -- TypeScript
    "tsx", -- TypeScript + JSX (React)
    "html",
    "css",
    "scss", -- SCSS/Sass

    -- ===== Backend & General =====
    "python",
    "go",
    "lua",
    "bash",
    "vim",

    -- ===== Functional & Multi-paradigm =====
    "haskell", -- Haskell
    "ocaml", -- OCaml
    "fsharp", -- F#
    "elixir", -- Elixir

    -- ===== Configuration & Data Formats =====
    "json",
    "yaml",
    "toml",
    "xml",
    "ini", -- .ini files
    "nix", -- Nix expressions

    -- ===== Documentation & Markup =====
    "markdown",
    "markdown_inline",
    "latex", -- LaTeX
    "rst", -- reStructuredText

    -- ===== Build & Infrastructure =====
    "dockerfile",
    "cmake", -- CMakeLists.txt
    "make", -- Makefiles

    -- ===== Version Control & Dev Tools =====
    "gitignore",
    "gitattributes",
    "gitcommit", -- Commit messages
    "git_rebase", -- Rebase files

    -- ===== Query & Specialized =====
    "sql", -- SQL
    "regex", -- Regular expressions
    "comment", -- For comment-based features

    -- ===== Misc =====
    "kulala_http",
  },
}
