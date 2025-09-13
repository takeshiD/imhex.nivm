local M = {}

local function is_lua51(bytes)
  if #bytes < 12 then
    return false
  end
  local b = { bytes:byte(1, 6) }
  -- 1B 4C 75 61 = ESC 'L' 'u' 'a'
  if b[1] ~= 0x1B or b[2] ~= 0x4C or b[3] ~= 0x75 or b[4] ~= 0x61 then
    return false
  end
  if b[5] ~= 0x51 then
    return false
  end -- version 0x51 (Lua 5.1)
  return true
end

local function decode_header(bytes)
  local off = 1
  local function read_u8()
    local v = bytes:byte(off)
    off = off + 1
    return v
  end
  local function read_sig(n)
    local s = { bytes:byte(off, off + n - 1) }
    off = off + n
    return s
  end

  local sig = read_sig(4)
  local version = read_u8()
  local format = read_u8()
  local endian = read_u8()
  local size_int = read_u8()
  local size_size_t = read_u8()
  local size_instr = read_u8()
  local size_lua_num = read_u8()
  local integral_flag = read_u8()

  return {
    format = "Lua bytecode",
    signature = string.format("0x%02X 0x%02X 0x%02X 0x%02X", sig[1], sig[2], sig[3], sig[4]),
    version = string.format("0x%02X (%d.%d)", version, math.floor(version / 16), version % 16),
    header = {
      format = format,
      endianness = (endian == 1) and "little" or "big",
      sizeof_int = size_int,
      sizeof_size_t = size_size_t,
      sizeof_instruction = size_instr,
      sizeof_lua_Number = size_lua_num,
      lua_Number_integral = (integral_flag ~= 0),
    },
    note = "Only header parsed for Lua 5.1",
  }
end

function M.register(Decode)
  Decode.register("lua51", is_lua51, function(bytes)
    return decode_header(bytes)
  end)
end

return M
