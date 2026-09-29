local M = {}

--- Strip CSI/OSC/simple ESC sequences so log buffers stay readable.
---@param str string
---@return string
function M.strip(str)
  -- CSI: ESC [ <params: digits ; ? > = <  > <final byte>
  str = str:gsub("\27%[[%d;?]*[%a@~]", "")
  -- OSC/DCS/SOS/PM/APC terminated by ST (ESC \)
  str = str:gsub("\27[%]PX^_].-\27\\", "")
  -- OSC/DCS/SOS/PM/APC terminated by BEL
  str = str:gsub("\27[%]PX^_].-\7", "")
  -- Simple two-byte escapes: ESC <letter>
  str = str:gsub("\27[%a\\^_]", "")
  return str
end

return M
