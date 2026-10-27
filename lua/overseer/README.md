# Project tasks

`<leader>ts` opens the Overseer project task picker. Custom providers in
`template/` are discovered automatically alongside Overseer's built-in providers.

## uv

The uv provider finds the nearest `pyproject.toml` above the project search
folder and lists its `[project.scripts]` entries:

```toml
[project.scripts]
serve = "myapp.server:main"
worker = "myapp.worker:main"
```

These become `uv run serve` and `uv run worker`, run from the directory containing
that file. The project must be configured to install its entry points (normally
with a build system). Script values are Python entry points, not shell commands.

Discovery requires `uv` and Python 3.11+ with `tomllib` on Neovim's PATH. It only
reads TOML: no project code executes and no environment is created until a task
is run. Projects without `[project.scripts]` add no uv tasks.
