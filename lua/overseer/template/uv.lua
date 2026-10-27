local read_scripts = [[
import json, sys, tomllib
with open(sys.argv[1], "rb") as stream:
    project = tomllib.load(stream).get("project", {})
scripts = project.get("scripts", {})
if not isinstance(scripts, dict) or not all(
    isinstance(name, str) and isinstance(target, str)
    for name, target in scripts.items()
):
    raise ValueError("project.scripts must contain string entry points")
print(json.dumps(scripts))
]]

---@type overseer.TemplateFileProvider
return {
  generator = function(opts)
    if vim.fn.executable "uv" == 0 then
      return "Could not find command 'uv'"
    end
    local project = vim.fs.find("pyproject.toml", {
      upward = true,
      type = "file",
      path = opts.dir,
    })[1]
    if not project then
      return "No pyproject.toml file found"
    end
    if vim.fn.executable "python3" == 0 then
      return "uv task discovery requires Python 3.11+ (tomllib)"
    end
    -- Parse TOML without running project code or creating a uv environment.
    local result = vim
      .system({ "python3", "-c", read_scripts, project }, {
        text = true,
      })
      :wait(5000)
    if result.code ~= 0 then
      return "Cannot read uv project scripts: "
        .. vim.trim(result.stderr or "Python failed")
    end
    local ok, scripts = pcall(vim.json.decode, result.stdout)
    if not ok or type(scripts) ~= "table" then
      return "Cannot decode uv project scripts"
    end
    local tasks = {}
    for _, name in ipairs(vim.tbl_keys(scripts)) do
      table.insert(tasks, {
        name = "uv run " .. name,
        desc = scripts[name],
        builder = function()
          return {
            cmd = { "uv", "run", name },
            cwd = vim.fs.dirname(project),
          }
        end,
      })
    end
    table.sort(tasks, function(a, b)
      return a.name < b.name
    end)
    return tasks
  end,
}
