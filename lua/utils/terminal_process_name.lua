local M = {}
local pretty = {
  lazydocker = "Lazydocker",
  btop = "Top",
  htop = "Top",
  top = "Top",
  ranger = "Ranger",
  yazi = "Yazi",
  lf = "Lf",
  nnn = "Nnn",
  lazygit = "Lazygit",
  git = "Git",
  tig = "Tig",
  ncdu = "Ncdu",
  k9s = "K9s",
  docker = "Docker",
  podman = "Podman",
  kubectl = "Kubectl",
  python = "Python",
  python3 = "Python",
  node = "Node",
  npm = "Npm",
  pnpm = "Pnpm",
  yarn = "Yarn",
  bun = "Bun",
  deno = "Deno",
  uv = "Uv",
  cargo = "Cargo",
  rustc = "Rust",
  go = "Go",
  java = "Java",
  sbt = "Sbt",
  bash = "Bash",
  zsh = "Zsh",
  fish = "Fish",
  sh = "Shell",
  nvim = "Neovim",
  vim = "Vim",
  less = "Less",
  man = "Man",
  claude = "Claude",
  codex = "Codex",
}

local function read(path)
  local file = io.open(path, "rb")
  if not file then
    return
  end
  local contents = file:read "*a"
  file:close()
  return contents
end

local ssh_values = {}
for option in ("B b c D E e F I i J L l m O o P p Q R S W w"):gmatch "%S+" do
  ssh_values[option] = true
end

function M.label(argv)
  local name = vim.fn.fnamemodify(argv[1] or "", ":t"):gsub("^%-", "")
  if name == "ssh" then
    local destination, hostname
    local i = 2
    while i <= #argv do
      local arg = argv[i]
      if arg == "--" then
        destination = argv[i + 1]
        break
      elseif arg:sub(1, 1) ~= "-" then
        destination = arg
        break
      else
        local option = arg:sub(2, 2)
        local value = arg:sub(3)
        if ssh_values[option] and value == "" then
          i = i + 1
          value = argv[i] or ""
        end
        if option == "o" then
          hostname = value:match "^[Hh][Oo][Ss][Tt][Nn][Aa][Mm][Ee]=(.+)$"
            or hostname
        end
      end
      i = i + 1
    end
    if hostname or destination then
      local host = (hostname or destination)
        :gsub("^ssh://", "")
        :gsub("^.-@", "")
      if host:sub(1, 1) == "[" then
        return host:match "^%[([^%]]+)%]" or host
      end
      return host:gsub(":%d+$", "")
    end
    return "SSH"
  end
  return pretty[name] or (name:gsub("^%l", string.upper))
end

-- Read the SSH process's established TCP peer, including config aliases and DNS names.
local function ssh_peer(pid)
  local sockets = {}
  local scan = vim.uv.fs_scandir("/proc/" .. pid .. "/fd")
  if not scan then
    return
  end
  while true do
    local name = vim.uv.fs_scandir_next(scan)
    if not name then
      break
    end
    local link = vim.uv.fs_readlink("/proc/" .. pid .. "/fd/" .. name) or ""
    local inode = link:match "^socket:%[(%d+)%]$"
    if inode then
      sockets[inode] = true
    end
  end
  for _, family in ipairs { "tcp", "tcp6" } do
    for line in
      (read("/proc/" .. pid .. "/net/" .. family) or ""):gmatch "[^\n]+"
    do
      local columns = vim.split(vim.trim(line), "%s+")
      if columns[4] == "01" and sockets[columns[10]] then
        local hex = columns[3]:match "^(%x+):"
        if hex and #hex == 8 then
          local bytes = {}
          for i = 7, 1, -2 do
            bytes[#bytes + 1] = tonumber(hex:sub(i, i + 1), 16)
          end
          return table.concat(bytes, ".")
        elseif hex and #hex == 32 then
          local bytes = ""
          for word = 1, 32, 8 do
            for i = word + 6, word, -2 do
              bytes = bytes .. hex:sub(i, i + 1)
            end
          end
          local groups = {}
          for i = 1, 32, 4 do
            groups[#groups + 1] =
              string.format("%x", tonumber(bytes:sub(i, i + 3), 16))
          end
          return table.concat(groups, ":")
        end
      end
    end
  end
end

function M.current(pid)
  if type(pid) ~= "number" or pid <= 0 then
    return
  end
  local stat = read("/proc/" .. pid .. "/stat")
  if not stat then
    return
  end
  -- Fields after the parenthesized comm start at field 3; tpgid is field 8.
  local fields = vim.split(stat:match "^%d+ %(.+%) (.*)$" or "", "%s+")
  local foreground = tonumber(fields[6])
  if foreground and foreground > 0 then
    pid = foreground
  end
  local cmdline = read("/proc/" .. pid .. "/cmdline")
  if not cmdline or cmdline == "" then
    return
  end
  local argv = vim.split(cmdline, "\0", { plain = true, trimempty = true })
  if vim.fn.fnamemodify(argv[1] or "", ":t") == "ssh" then
    return ssh_peer(pid) or M.label(argv)
  end
  return M.label(argv)
end

return M
