-- nvim --headless -u NONE -i NONE -l tests/markdown_math.lua [config-root]
local config = vim.fn.stdpath "config"
local root = arg[1] or config
vim.opt.rtp:prepend(config .. "/data/tree-sitter")
vim.opt.rtp:prepend(config .. "/data/lazy/nvim-treesitter/runtime")
vim.opt.rtp:prepend(config .. "/data/lazy/render-markdown.nvim")
vim.opt.rtp:prepend(root)
require "configs.render-markdown"
local math = require "configs.markdown-math"
local lines = {
  [[unicode Ж $\alpha + \beta \leq \Gamma \times \infty$]],
  [[$\cdot \bullet \ldots \dots \cdots \vdots \ddots$]],
  [[$\left\langle x \right\rangle \left. x \right| \sin x$]],
  [[$x^2 a_i \hat{x} \frac{1}{x} \unknown \alphabogus \\alpha$]],
  "",
  "$$",
  [[\theta \rightarrow \Omega]],
  "$$",
  "",
  [[prose \alpha and `$\alpha$`]],
  "```latex",
  [[$\alpha \left(x\right)$]],
  "```",
  "",
  [[$\left\{x\right\} \left\|x\right\| \ldotp \cdotp$]],
}
local checks = 0
local function eq(a, b, name)
  checks = checks + 1
  assert(
    vim.deep_equal(a, b),
    name .. ": " .. vim.inspect(a) .. " ~= " .. vim.inspect(b)
  )
end
local function marks(buf)
  local parser = vim.treesitter.get_parser(buf, "markdown")
  parser:parse(true)
  local result = {}
  parser:for_each_tree(function(tree, language)
    if language:lang() == "latex" then
      vim.list_extend(
        result,
        math.parse { buf = buf, root = tree:root(), last = true }
      )
    end
  end)
  table.sort(result, function(a, b)
    return a.start_row < b.start_row
      or (a.start_row == b.start_row and a.start_col < b.start_col)
  end)
  return result
end
for _, ft in ipairs { "markdown", "todotxt-preview" } do
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = ft
  vim.bo[buf].modified = false
  vim.treesitter.start(buf, "markdown")
  local undo = vim.fn.undotree()
  local result = marks(buf)
  local byrow = {}
  local ns = vim.api.nvim_create_namespace "markdown-math-test"
  for _, m in ipairs(result) do
    local replacement = m.opts.virt_text and m.opts.virt_text[1][1]
      or m.opts.conceal
    if m.opts.conceal ~= nil then
      byrow[m.start_row] = byrow[m.start_row] or {}
      table.insert(byrow[m.start_row], replacement)
    end
    vim.api.nvim_buf_set_extmark(buf, ns, m.start_row, m.start_col, m.opts)
  end
  eq(
    byrow[0],
    { " ", "α", "β", "≤", "Γ", "×", "∞", " " },
    "Greek/operators"
  )
  eq(
    byrow[1],
    { " ", "⋅", "•", "…", "…", "⋯", "⋮", "⋱", " " },
    "dots"
  )
  eq(
    byrow[2],
    { " ", "", "⟨", "", "⟩", "", "", "", "sin", " " },
    "delimiters/functions"
  )
  eq(
    byrow[3],
    { " ", "", "(", ") ÷ ", "(", ")", " " },
    "fraction with scripts/accents/unknown/escaped unchanged"
  )
  eq(byrow[5], { " " }, "display opening LaTeX icon")
  eq(byrow[7], { "  " }, "display closing delimiter spaces")
  eq(byrow[6], { "θ", "→", "Ω" }, "display math")
  eq(byrow[9], nil, "prose/inline code")
  eq(byrow[11], nil, "LaTeX fence")
  eq(
    byrow[14],
    { " ", "", "{", "", "}", "", "‖", "", "‖", ".", "⋅", " " },
    "escaped delimiters and dot aliases"
  )
  local shared = vim.treesitter.query.get("markdown_inline", "highlights")
  local hl = vim.treesitter.highlighter.active[buf]
  local wrapper = hl:get_query "markdown_inline"
  local original = wrapper:query()
  math.render { buf = buf }
  local filtered = wrapper:query()
  eq(filtered ~= original, true, "local highlighter query")
  eq(
    vim.treesitter.query.get("markdown_inline", "highlights"),
    shared,
    "shared query intact"
  )
  for _, lang in ipairs { "markdown", "markdown_inline", "latex" } do
    local q = hl:get_query(lang):query()
    if q then
      for _, pattern in pairs(q.info.patterns) do
        for _, directive in ipairs(pattern) do
          eq(
            directive[1] == "set!"
              and (directive[2] == "conceal" or directive[2] == "conceal_lines"),
            false,
            "no syntax conceal"
          )
        end
      end
    end
  end
  math.clear { buf = buf }
  eq(wrapper:query(), original, "query restored")
  eq(vim.api.nvim_buf_get_lines(buf, 0, -1, false), lines, "source unchanged")
  eq(vim.bo[buf].modified, false, "modified unchanged")
  eq(vim.fn.undotree(), undo, "undo unchanged")
  vim.api.nvim_buf_set_lines(buf, 0, 1, false, { [[$\beta$]] })
  local changed = marks(buf)
  local replacement
  for _, m in ipairs(changed) do
    if
      m.start_row == 0
      and m.opts.virt_text
      and m.opts.virt_text[1][1] ~= " "
    then
      replacement = m.opts.virt_text[1][1]
    end
  end
  eq(replacement, "β", "edit refresh")
  vim.api.nvim_buf_set_lines(buf, 0, 1, false, { [[\beta]] })
  for _, m in ipairs(marks(buf)) do
    assert(m.start_row ~= 0, "unclosed math must stay literal")
  end
  vim.api.nvim_buf_delete(buf, { force = true })
end

local function display(buf)
  local source =
    table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  local starts, offset = {}, 0
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    starts[i - 1], offset = offset, offset + #line + 1
  end
  local result, cursor = {}, 0
  for _, m in ipairs(marks(buf)) do
    if m.opts.conceal ~= nil then
      local start = starts[m.start_row] + m.start_col
      local finish = starts[m.opts.end_row] + m.opts.end_col
      assert(start >= cursor, "overlapping math replacements")
      result[#result + 1] = source:sub(cursor + 1, start)
      result[#result + 1] = m.opts.virt_text and m.opts.virt_text[1][1] or ""
      cursor = finish
    end
  end
  result[#result + 1] = source:sub(cursor + 1)
  return table.concat(result)
end
local fixtures = {
  { [[$$x+\psi$$]], " x+ψ  " },
  { [[$x+\$5$]], [[ x+\$5 ]] },
  { [[$\frac{xy}{x+a}$]], [[$(xy) ÷ (x+a)$]] },
  {
    [[$\psi(x,y)=\sqrt{xy},\qquad \psi(x,y)\ge\sqrt{k}$]],
    [[$ψ(x,y)=√(xy),     ψ(x,y)≥√(k)$]],
  },
  { [[$V'(c)=\sqrt{\frac{k}{c}}$]], [[$V'(c)=√((k) ÷ (c))$]] },
  {
    [[$V''(c)=-\frac{\sqrt{k}}{2c^{3/2}}$]],
    [[$V''(c)=-(√(k)) ÷ (2c^{3/2})$]],
  },
  {
    [[$q_\gamma(a)=\frac{y\gamma a}{x+\gamma a}$]],
    [[$q_γ(a)=(yγ a) ÷ (x+γ a)$]],
  },
  {
    [[$\min_{x>0}\left(cx+\frac{k}{x}\right)$]],
    [[$min_{x>0}(cx+(k) ÷ (x))$]],
  },
  { [[$\bar p\quad x^2 a_i \hat{x}$]], [[$\bar p   x^2 a_i \hat{x}$]] },
  { [[$x\,y\;z\!w\ a$]], [[$x y zw a$]] },
  { [[$\sqrt[3]{x} \frac12$]], [[$\sqrt[3]{x} \frac12$]] },
  { [[$\frac{a}{b$]], [[$\frac{a}{b$]] },
  { [[$\sqrt{x$]], [[$\sqrt{x$]] },
  { [[$\\frac{a}{b}$]], [[$\\frac{a}{b}$]] },
  { [[$\dfrac{a}{\tfrac{b}{c}}$]], [[$(a) ÷ ((b) ÷ (c))$]] },
  { "$$\n\\frac{a}\n{\\sqrt{b}}\n$$", "$$\n(a) ÷ \n(√(b))\n$$" },
}
for _, fixture in ipairs(fixtures) do
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_lines(
    buf,
    0,
    -1,
    false,
    vim.split(fixture[1], "\n", { plain = true })
  )
  eq(
    display(buf),
    fixture[2]
      :gsub("^%$+", function(d)
        return #d == 2 and " " or string.rep(" ", #d)
      end)
      :gsub("%$+$", function(d)
        return string.rep(" ", #d)
      end),
    "linear math: " .. fixture[1]
  )
  vim.api.nvim_buf_delete(buf, { force = true })
end
-- Optional real-note regression; the vault is read-only and never written.
if arg[2] then
  local buf = vim.api.nvim_create_buf(false, true)
  local source = vim.fn.readfile(arg[2])
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, source)
  vim.bo[buf].filetype = "markdown"
  local rendered = display(buf)
  for _, expected in ipairs {
    "f(x)=(k) ÷ (x)",
    "ψ(x,y)=√(xy)",
    "p=(ψ_x) ÷ (ψ_y)",
    "V'(c)=√((k) ÷ (c))",
    "V''(c)=-(√(k)) ÷ (2c^{3/2})",
    "h_u=h_v=(1) ÷ (2√(u+v))",
    "q_γ(a)=(yγ a) ÷ (x+γ a)",
  } do
    eq(rendered:find(expected, 1, true) ~= nil, true, "AMM note: " .. expected)
  end
  eq(rendered:find("\\frac", 1, true), nil, "all note fractions render")
  eq(rendered:find("\\sqrt", 1, true), nil, "all note roots render")
  eq(rendered:find("\\qquad", 1, true), nil, "all note spacing renders")
  eq(
    vim.api.nvim_buf_get_lines(buf, 0, -1, false),
    source,
    "vault source untouched"
  )
  vim.api.nvim_buf_delete(buf, { force = true })
end
print("markdown math total: " .. checks .. " checks passed")
