-- Relative timestamps for compact UI (Telescope git branches, etc.).
--
--   <= 1 min          ~now
--   1 min – 1 h       4m ago / 23m ago
--   1 h – 4 h         1h 20m ago
--   4 h – 25 h        7h ago
--   25 h – 45 h       yesterday
--   45 h – 6 days     Mon
--   6 days – 1 year   4 mar
--   > 1 year          4 mar 2025

local MIN = 60
local HOUR = 60 * MIN
local DAY = 24 * HOUR
local YEAR = 365 * DAY

local WEEKDAYS = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
local MONTHS = { "jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec" }

---@param time integer|string unix seconds
---@param now? integer unix seconds, defaults to os.time()
---@return string
return function(time, now)
  local ts = tonumber(time)
  if not ts then
    return ""
  end

  now = now or os.time()
  local delta = now - ts
  if delta < 0 then
    delta = 0
  end

  if delta <= MIN then
    return "~now"
  end

  if delta < HOUR then
    return string.format("%dm ago", math.floor(delta / MIN))
  end

  if delta < 4 * HOUR then
    local hours = math.floor(delta / HOUR)
    local mins = math.floor((delta % HOUR) / MIN)
    return string.format("%dh %dm ago", hours, mins)
  end

  if delta < 25 * HOUR then
    return string.format("%dh ago", math.floor(delta / HOUR))
  end

  if delta < 45 * HOUR then
    return "yesterday"
  end

  local t = os.date("*t", ts)
  if delta < 6 * DAY then
    return WEEKDAYS[t.wday]
  end

  local date = string.format("%d %s", t.day, MONTHS[t.month])
  if delta >= YEAR then
    date = date .. " " .. t.year
  end
  return date
end
