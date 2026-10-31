local M = {}

-- Linear Unicode math; scripts and accents keep their original syntax.
local symbols = {
  alpha = "α",
  beta = "β",
  gamma = "γ",
  delta = "δ",
  epsilon = "ϵ",
  varepsilon = "ε",
  zeta = "ζ",
  eta = "η",
  theta = "θ",
  vartheta = "ϑ",
  iota = "ι",
  kappa = "κ",
  varkappa = "ϰ",
  lambda = "λ",
  mu = "μ",
  nu = "ν",
  xi = "ξ",
  omicron = "ο",
  pi = "π",
  varpi = "ϖ",
  rho = "ρ",
  varrho = "ϱ",
  sigma = "σ",
  varsigma = "ς",
  tau = "τ",
  upsilon = "υ",
  phi = "ϕ",
  varphi = "φ",
  chi = "χ",
  psi = "ψ",
  omega = "ω",
  Gamma = "Γ",
  Delta = "Δ",
  Theta = "Θ",
  Lambda = "Λ",
  Xi = "Ξ",
  Pi = "Π",
  Sigma = "Σ",
  Upsilon = "Υ",
  Phi = "Φ",
  Psi = "Ψ",
  Omega = "Ω",
  ["{"] = "{",
  ["}"] = "}",
  ["|"] = "‖",
  ldotp = ".",
  cdotp = "⋅",
  centerdot = "⋅",
  dotsc = "…",
  dotsb = "⋯",
  dotsm = "⋯",
  dotsi = "⋯",
  dotso = "…",
  cdot = "⋅",
  bullet = "•",
  ldots = "…",
  dots = "…",
  cdots = "⋯",
  vdots = "⋮",
  ddots = "⋱",
  times = "×",
  div = "÷",
  pm = "±",
  mp = "∓",
  ast = "∗",
  star = "⋆",
  circ = "∘",
  le = "≤",
  leq = "≤",
  ge = "≥",
  geq = "≥",
  ne = "≠",
  neq = "≠",
  approx = "≈",
  equiv = "≡",
  sim = "∼",
  simeq = "≃",
  propto = "∝",
  ll = "≪",
  gg = "≫",
  to = "→",
  rightarrow = "→",
  leftarrow = "←",
  leftrightarrow = "↔",
  mapsto = "↦",
  Rightarrow = "⇒",
  Leftarrow = "⇐",
  Leftrightarrow = "⇔",
  implies = "⇒",
  iff = "⇔",
  longrightarrow = "⟶",
  longleftarrow = "⟵",
  longleftrightarrow = "⟷",
  Longrightarrow = "⟹",
  Longleftarrow = "⟸",
  Longleftrightarrow = "⟺",
  uparrow = "↑",
  downarrow = "↓",
  updownarrow = "↕",
  nearrow = "↗",
  searrow = "↘",
  infty = "∞",
  partial = "∂",
  nabla = "∇",
  int = "∫",
  iint = "∬",
  iiint = "∭",
  oint = "∮",
  sum = "∑",
  prod = "∏",
  ["in"] = "∈",
  notin = "∉",
  ni = "∋",
  subset = "⊂",
  supset = "⊃",
  subseteq = "⊆",
  supseteq = "⊇",
  cup = "∪",
  cap = "∩",
  setminus = "∖",
  emptyset = "∅",
  varnothing = "∅",
  forall = "∀",
  exists = "∃",
  nexists = "∄",
  neg = "¬",
  lnot = "¬",
  land = "∧",
  wedge = "∧",
  lor = "∨",
  vee = "∨",
  langle = "⟨",
  rangle = "⟩",
  lVert = "‖",
  rVert = "‖",
  Vert = "‖",
  lvert = "|",
  rvert = "|",
  vert = "|",
  lbrace = "{",
  rbrace = "}",
  lfloor = "⌊",
  rfloor = "⌋",
  lceil = "⌈",
  rceil = "⌉",
  sin = "sin",
  cos = "cos",
  tan = "tan",
  cot = "cot",
  sec = "sec",
  csc = "csc",
  sinh = "sinh",
  cosh = "cosh",
  tanh = "tanh",
  log = "log",
  ln = "ln",
  exp = "exp",
  lim = "lim",
  min = "min",
  max = "max",
  quad = "  ",
  qquad = "    ",
  enspace = " ",
  thinspace = " ",
  [" "] = " ",
  [","] = " ",
  [";"] = " ",
  [":"] = " ",
  ["!"] = "",
}

-- Strip conceal directives from a *buffer's* highlighter queries, never the
-- shared query cache. Keep captures/predicates and all other highlighting intact.
-- get_query()._query is the one Neovim internal used here; isolated for upgrades.
local queries = setmetatable({}, { __mode = "k" })
local originals = setmetatable({}, { __mode = "k" })
local function visible_query(language, original)
  if queries[original] then
    return queries[original]
  end
  local parts = {}
  for _, path in ipairs(vim.treesitter.query.get_files(language, "highlights")) do
    parts[#parts + 1] = table.concat(vim.fn.readfile(path), "\n")
  end
  local text = table.concat(parts, "\n")
  -- Values are query strings, possibly containing an escaped quote.
  text = text:gsub('%(#set!%s+conceal[%w_]*%s+"[^\n]-"%)', "")
  text = text:gsub('%(#set!%s+@[%w_.]+%s+conceal[%w_]*%s+"[^\n]-"%)', "")
  queries[original] = vim.treesitter.query.parse(language, text)
  return queries[original]
end

function M.render(ctx)
  local highlighter = vim.treesitter.highlighter.active[ctx.buf]
  if not highlighter then
    return
  end
  for _, language in ipairs { "markdown", "markdown_inline", "latex" } do
    local wrapper = highlighter:get_query(language)
    if wrapper._query and not originals[wrapper] then
      local original = wrapper._query
      wrapper._query = visible_query(language, original)
      originals[wrapper] = original
    end
  end
end

function M.clear(ctx)
  local highlighter = vim.treesitter.highlighter.active[ctx.buf]
  if not highlighter then
    return
  end
  for _, language in ipairs { "markdown", "markdown_inline", "latex" } do
    local wrapper = highlighter:get_query(language)
    if originals[wrapper] then
      wrapper._query = originals[wrapper]
      originals[wrapper] = nil
    end
  end
end

function M.parse(ctx)
  local row, col = ctx.root:range()
  -- LaTeX injections also occur in fenced code. Only latex_block nodes from
  -- Markdown inline syntax represent the math regions we intend to render.
  local inline = vim.treesitter.get_parser(ctx.buf):children().markdown_inline
  local parent = inline
    and inline:named_node_for_range(
      { row, col, row, col },
      { ignore_injections = true }
    )
  while parent and parent:type() ~= "latex_block" do
    parent = parent:parent()
  end
  if not parent then
    return {}
  end

  local sr, sc, er, ec = ctx.root:range()
  local marks = {
    {
      conceal = "latex",
      start_row = sr,
      start_col = sc,
      opts = {
        end_row = er,
        end_col = ec,
        hl_group = "RenderMarkdownMath",
        priority = 180,
      },
    },
  }
  local function mark(node, replacement)
    local sr, sc, er, ec = node:range()
    -- Conceal's replacement character always uses the global Conceal color.
    -- Inline virtual text gives every replacement the same color as the formula.
    local opts = { end_row = er, end_col = ec, conceal = "", priority = 200 }
    if replacement ~= "" then
      opts.virt_text = { { replacement, "RenderMarkdownMath" } }
      opts.virt_text_pos = "inline"
    end
    marks[#marks + 1] =
      { conceal = "latex", start_row = sr, start_col = sc, opts = opts }
  end
  local function walk(node)
    local kind = node:type()
    if kind == "generic_command" and not node:has_error() then
      local command = node:field("command")[1]
      local name = command and vim.treesitter.get_node_text(command, ctx.buf)
      local args = node:field "arg"
      local count = (name == "\\frac" or name == "\\dfrac" or name == "\\tfrac")
          and 2
        or name == "\\sqrt" and 1
      local valid = count and #args >= count
      for i = 1, count or 0 do
        local arg = args[i]
        valid = valid
          and arg
          and arg:type() == "curly_group"
          and arg:child(0):type() == "{"
          and arg:child(arg:child_count() - 1):type() == "}"
      end
      if valid then
        mark(command, count == 1 and "√" or "")
        for i = 1, count do
          local arg = args[i]
          mark(arg:child(0), "(")
          mark(
            arg:child(arg:child_count() - 1),
            count == 2 and i == 1 and ") ÷ " or ")"
          )
          -- Visit arguments, not the command again: nested roots/fractions and
          -- Greek symbols render independently without overlapping ranges.
          for child in arg:iter_children() do
            if child:named() then
              walk(child)
            end
          end
        end
        -- Extra argument groups do not belong to the fraction/root.
        for i = count + 1, #args do
          walk(args[i])
        end
        return
      end
    end
    if kind == "$" or kind == "$$" then
      -- Use the same LaTeX Nerd Font glyph as nvim-web-devicons' tex icon.
      -- Only the opening display delimiter gets an icon; inline and closing
      -- delimiters remain spaces. Code and escaped dollars never reach this.
      local opening = kind == "$$"
        and node:parent():type() == "displayed_equation"
        and node:prev_sibling() == nil
      mark(
        node,
        opening and " "
          or string.rep(" ", #vim.treesitter.get_node_text(node, ctx.buf))
      )
    elseif kind == "command_name" then
      local text = vim.treesitter.get_node_text(node, ctx.buf)
      local command = text:match "^\\([A-Za-z]+)$"
        or text:match "^\\([{}| ,;:!])$"
      if symbols[command] then
        mark(node, symbols[command])
      end
    elseif kind == "\\left" or kind == "\\right" then
      mark(node, "")
      -- A dot here denotes an invisible delimiter, e.g. \left. x \right|.
      local next_node = node:next_sibling()
      if
        next_node and vim.treesitter.get_node_text(next_node, ctx.buf) == "."
      then
        mark(next_node, "")
      end
    end
    for child in node:iter_children() do
      walk(child)
    end
  end
  walk(ctx.root)
  return marks
end

return M
