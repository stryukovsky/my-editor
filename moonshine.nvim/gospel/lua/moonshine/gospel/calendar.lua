local M = {}

-- Julian day numbers keep calendar arithmetic independent of time zones and DST.
local function day_number(year, month, day, gregorian)
  local shift = math.floor((14 - month) / 12)
  local y = year + 4800 - shift
  local m = month + 12 * shift - 3
  local days = day + math.floor((153 * m + 2) / 5) + 365 * y + math.floor(y / 4)
  if gregorian then
    return days - math.floor(y / 100) + math.floor(y / 400) - 32045
  end
  return days - 32083
end

local function weekday(day)
  return (day + 1) % 7 -- Sunday = 0
end

local function pascha(year)
  -- Gauss's formula for Julian Easter, with M = 15 and N = 6.
  local moon = (19 * (year % 19) + 15) % 30
  local sunday = (2 * (year % 4) + 4 * (year % 7) + 6 * moon + 6) % 7
  return day_number(year, 3, 22) + moon + sunday
end

local function sunday_before(day)
  return day - 1 - (weekday(day) - 1) % 7
end

local function sunday_after(day)
  return day + 7 - weekday(day)
end

local function paschal_index(day, year)
  local easter = pascha(year)
  local triodion = easter - 70
  if day < triodion then
    year = year - 1
    easter = pascha(year)
  else
    triodion = pascha(year + 1) - 70
  end

  local after_cross = sunday_after(day_number(year, 9, 14))
  if day <= after_cross then
    local offset = day - easter
    -- With an early Pascha, repeat weeks 10 and/or 11 until the Lucan cycle begins.
    if offset > 168 then
      return 126 + day - after_cross
    end
    return offset
  end

  local offset = 168 + day - after_cross
  local forefathers = sunday_before(day_number(year, 12, 25)) - 7
  if day == forefathers then
    return 245
  elseif offset == 245 then
    return 168 + forefathers - after_cross
  end

  -- Theophany gap: repeat the end of the cycle, with week 17 inserted in a five-week gap.
  local cycle_end = after_cross + 112
  if day > cycle_end then
    offset = 280 - (triodion - day)
    if triodion - cycle_end == 35 then
      if offset < 260 then
        return offset + 7
      elseif offset < 267 then
        return offset - 98
      end
    end
  end
  return offset
end

local function feast_readings(data, day, year)
  local feasts = {}
  for date, entry in pairs(data.fixed) do
    local month, monthday = date:match "(%d+)-(%d+)"
    if day == day_number(year, tonumber(month), tonumber(monthday)) then
      feasts[entry[1]] = entry[2]
    end
  end

  for _, entry in ipairs(data.relative) do
    local kind, month, monthday, rule, target, ref = unpack(entry)
    for feast_year = year - 1, year + 1 do
      local feast = day_number(feast_year, month, monthday)
      local wday = weekday(feast)
      local scheduled
      if rule == "on_weekday" then
        if wday == target then
          scheduled = feast
        end
      elseif target == 0 then
        scheduled = sunday_before(feast)
        if
          month == 1
          and scheduled == sunday_after(day_number(feast_year - 1, 12, 25))
        then
          scheduled = day_number(feast_year, 1, 1)
        end
      elseif target == 7 and month == 12 and wday == 0 then
        scheduled = feast + 1
      elseif wday ~= target then
        scheduled = feast + target - wday
      end
      if scheduled == day then
        feasts[kind] = ref
      end
    end
  end
  return feasts
end

function M.readings(data, date)
  local day = day_number(date.year, date.month, date.day, true)
  local old_style_year = day < day_number(date.year, 1, 1) and date.year - 1
    or date.year
  local index = paschal_index(day, date.year)
  local regular = data.paschal[tostring(index)]
  local feasts = feast_readings(data, day, old_style_year)
  local special = feasts.special or feasts.lord
  local vigil = feasts.marian or feasts.vigil
  local feast = special or vigil or feasts.with_regular

  if not feast then
    return { regular }
  elseif not regular or regular == feast then
    return { feast }
  end

  -- Keep the principal movable feast when it coincides with a fixed commemoration.
  if
    index == 0
    or index == 39
    or index == 49
    or (index >= -8 and index < 0)
  then
    return (feasts.marian or index == 39) and { regular, feast } or { regular }
  elseif special then
    return { special }
  elseif vigil then
    return weekday(day) == 0 and { regular, vigil } or { vigil }
  end
  return { feast, regular }
end

return M
