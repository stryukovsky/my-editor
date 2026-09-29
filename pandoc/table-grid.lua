-- Redraw pipe tables as a full grid with wrapping cells.
-- Uses paragraph columns sized to \linewidth so long cells wrap instead of clipping.

local function blocks_to_latex(blocks)
  local doc = pandoc.Pandoc(blocks)
  local s = pandoc.write(doc, "latex")
  s = s:gsub("%s+$", "")
  s = s:gsub("\n+", " ")
  return s
end

local function p_column(align, ncols)
  -- n columns + (n+1) vertical rules; each cell has 2\tabcolsep padding
  local width = string.format(
    "\\dimexpr (\\linewidth - %d\\arrayrulewidth)/%d - 2\\tabcolsep \\relax",
    ncols + 1,
    ncols
  )
  if align == "AlignRight" then
    return ">{\\raggedleft\\arraybackslash}p{" .. width .. "}"
  elseif align == "AlignCenter" then
    return ">{\\centering\\arraybackslash}p{" .. width .. "}"
  end
  return ">{\\raggedright\\arraybackslash}p{" .. width .. "}"
end

function Table(tbl)
  local ncols = #tbl.colspecs
  local cols = {}
  for i, spec in ipairs(tbl.colspecs) do
    cols[i] = p_column(spec[1], ncols)
  end
  local colspec = "|" .. table.concat(cols, "|") .. "|"

  -- \mbox{}\par closes a run-in \paragraph heading before the table.
  local lines = {
    "\\mbox{}\\par\\vspace{0.8em}",
    "\\noindent\\begin{minipage}{\\linewidth}",
    "\\begin{tabular}{" .. colspec .. "}",
    "\\hline",
  }

  local function emit_row(row)
    local cells = {}
    for _, c in ipairs(row.cells) do
      cells[#cells + 1] = blocks_to_latex(c.contents)
    end
    lines[#lines + 1] = table.concat(cells, " & ") .. " \\\\"
    lines[#lines + 1] = "\\hline"
  end

  if tbl.head and tbl.head.rows then
    for _, row in ipairs(tbl.head.rows) do
      emit_row(row)
    end
  end
  for _, body in ipairs(tbl.bodies) do
    for _, row in ipairs(body.body) do
      emit_row(row)
    end
  end

  lines[#lines + 1] = "\\end{tabular}"
  lines[#lines + 1] = "\\end{minipage}"
  lines[#lines + 1] = "\\par\\vspace{0.8em}"
  return pandoc.RawBlock("latex", table.concat(lines, "\n"))
end
