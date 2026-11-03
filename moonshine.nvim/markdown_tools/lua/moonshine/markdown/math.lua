local M = {}

-- Linear Unicode math; scripts and accents keep their original syntax.
local symbols = {
  alpha = "α",
  beta = "β",
  gamma = "γ",
  delta = "δ",
  epsilon = "ε",
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

-- Expand tabs at their original display column before adding alignment spaces.
local function expand_tabs(text, column)
  return (
    text:gsub("([^\t]*)\t", function(prefix)
      column = column + vim.fn.strdisplaywidth(prefix)
      local cells = vim.fn.strdisplaywidth("\t", column)
      column = column + cells
      return prefix .. string.rep(" ", cells)
    end)
  )
end

-- Match source and rendered grapheme boundaries at equal display columns.
-- Overlay at source columns without concealing or inserting layout cells. Small
-- chunks follow wrapping/scrolling; wide glyphs and tabs stay indivisible.
local function cell_chunks(text, column)
  local result = {}
  for i = 0, vim.fn.strchars(text, 1) - 1 do
    local char = vim.fn.strcharpart(text, i, 1, true)
    local width = vim.fn.strdisplaywidth(char, column)
    result[#result + 1] = { text = char, width = width }
    column = column + width
  end
  return result
end

local function fitted_marks(row, sc, source, text, column, marks)
  local target = cell_chunks(text, column)
  local sw, tw, sb, tb, start_source, start_target, next_target =
    0, 0, 0, 0, 0, 0, 1
  for _, part in ipairs(cell_chunks(source, column)) do
    sw, sb = sw + part.width, sb + #part.text
    while target[next_target] and (tw < sw or target[next_target].width == 0) do
      local char = target[next_target]
      tw, tb, next_target = tw + char.width, tb + #char.text, next_target + 1
    end
    if sw == tw then
      marks[#marks + 1] = {
        conceal = "latex",
        start_row = row,
        start_col = sc + start_source,
        opts = {
          end_row = row,
          end_col = sc + sb,
          priority = 200,
          virt_text = {
            { text:sub(start_target + 1, tb), "RenderMarkdownMath" },
          },
          virt_text_pos = "overlay",
          hl_mode = "replace",
        },
      }
      start_source, start_target = sb, tb
    end
  end
end

local function fit_groups(buf, groups, marks)
  -- strdisplaywidth observes this buffer's tabstop/vartabstop settings.
  vim.api.nvim_buf_call(buf, function()
    for _, group in ipairs(groups) do
      table.sort(group.changes, function(a, b)
        return a.row < b.row or (a.row == b.row and a.col < b.col)
      end)
      local lines =
        vim.api.nvim_buf_get_lines(buf, group.sr, group.er + 1, false)
      local fitted, fits, change = {}, true, 1
      for row = group.sr, group.er do
        local line = lines[row - group.sr + 1]
        local sc = row == group.sr and group.sc or 0
        local ec = row == group.er and group.ec or #line
        local source, parts, cursor = line:sub(sc + 1, ec), {}, sc
        while group.changes[change] and group.changes[change].row == row do
          local item = group.changes[change]
          parts[#parts + 1] = line:sub(cursor + 1, item.col)
          parts[#parts + 1] = item.text
          cursor, change = item.ec, change + 1
        end
        parts[#parts + 1] = line:sub(cursor + 1, ec)
        local column = vim.fn.strdisplaywidth(line:sub(1, sc))
        local text = expand_tabs(table.concat(parts), column)
        local width = vim.fn.strdisplaywidth(source, column)
        local gap = width - vim.fn.strdisplaywidth(text)
        if gap < 0 then
          -- A split expression can expand a brace-only row. Keep that complete
          -- expression literal rather than changing columns or truncating math.
          fits = false
          break
        end
        if text ~= source then
          local left = math.floor(gap / 2)
          text = string.rep(" ", left) .. text .. string.rep(" ", gap - left)
          fitted_marks(row, sc, source, text, column, fitted)
        end
      end
      if fits then
        vim.list_extend(marks, fitted)
      end
    end
  end)
end

local function collect(ctx)
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
    return nil, {}
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
  local groups, enclosing = {}, nil
  local function group_for(node)
    local sr, sc, er, ec = node:range()
    local group = { sr = sr, sc = sc, er = er, ec = ec, changes = {} }
    groups[#groups + 1] = group
    return group
  end
  -- Collect all readable math into one group. Only its outer padding restores
  -- source width; individual symbols and nested expressions stay compact.
  local formula = group_for(ctx.root)
  enclosing = formula
  local function mark(node, replacement)
    local sr, sc, er, ec = node:range()
    local group = enclosing or group_for(node)
    group.changes[#group.changes + 1] =
      { row = sr, col = sc, ec = ec, text = replacement }
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
        -- Nested structures contribute readable text to the shared formula
        -- body; they do not get independent compensation padding.
        local previous = enclosing
        enclosing = enclosing or group_for(node)
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
        enclosing = previous
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
      -- Delimiters keep their own spans, so the display icon stays at the
      -- opening $$ and compensation is placed around the formula body.
      local dr, dc, der, dec = node:range()
      if dr == formula.sr and dc == formula.sc then
        formula.sr, formula.sc = der, dec
      end
      if der == formula.er and dec == formula.ec then
        formula.er, formula.ec = dr, dc
      end
      local previous = enclosing
      enclosing = nil
      mark(
        node,
        opening and ""
          or string.rep(" ", #vim.treesitter.get_node_text(node, ctx.buf))
      )
      enclosing = previous
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
  return groups, marks
end

function M.parse(ctx)
  -- Preview math has already been converted before table/prose layout. Never
  -- interpret math-looking text in the resulting table grid as source math.
  if require("render-markdown.core.preview").get(ctx.buf) then
    return {}
  end
  local groups, marks = collect(ctx)
  if groups then
    fit_groups(ctx.buf, groups, marks)
  end
  return marks
end

-- Materialize compact math in a copied document before preview tables and prose
-- are measured. Work from original syntax ranges, preserving source row counts,
-- code spans/fences, unknown commands, and the editable source buffer itself.
function M.lines(buf, lines)
  local output = vim.deepcopy(lines)
  local ok, parser = pcall(vim.treesitter.get_parser, buf, "markdown")
  if not ok or not parser or not pcall(parser.parse, parser, true) then
    return output
  end
  local changes = {}
  parser:for_each_tree(function(tree, language)
    if language:lang() ~= "latex" then
      return
    end
    local groups = collect { buf = buf, root = tree:root() }
    for _, group in ipairs(groups or {}) do
      for _, item in ipairs(group.changes) do
        -- A literal ASCII pipe would become a new Markdown table separator.
        -- Use the Unicode math bar in materialized text instead.
        local text = item.text == "|" and "∣" or item.text
        changes[#changes + 1] =
          { row = item.row, col = item.col, ec = item.ec, text = text }
      end
    end
  end)
  table.sort(changes, function(a, b)
    return a.row > b.row or (a.row == b.row and a.col > b.col)
  end)
  for _, item in ipairs(changes) do
    local line = output[item.row + 1]
    output[item.row + 1] = line:sub(1, item.col)
      .. item.text
      .. line:sub(item.ec + 1)
  end
  return output
end

return M
