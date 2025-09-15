---@class Lua51HeaderFields
---@field format integer
---@field endianness string
---@field sizeof_int integer
---@field sizeof_size_t integer
---@field sizeof_instruction integer
---@field sizeof_lua_Number integer
---@field lua_Number_integral boolean

-- ---@class Lua51Proto
-- ---@field source string|nil
-- ---@field linedefined integer
-- ---@field lastlinedefined integer
-- ---@field nupvalues integer
-- ---@field numparams integer
-- ---@field is_vararg integer
-- ---@field maxstacksize integer
-- ---@field code any
-- ---@field constants any
-- ---@field protos Lua51Proto[]
-- ---@field debug any
--
---@class Lua51DecodeResult
---@field format string
---@field signature string
---@field version string
---@field header Lua51HeaderFields
---@field proto Lua51Proto

local M = {}

---@param bytes string
---@return boolean
local function is_lua51(bytes)
    if #bytes < 18 then -- header(12) + LUAC_DATA(6)
        return false
    end
    local b = { bytes:byte(1, 6) }
    -- 1B 4C 75 61 = ESC 'L' 'u' 'a'
    if b[1] ~= 0x1B or b[2] ~= 0x4C or b[3] ~= 0x75 or b[4] ~= 0x61 then
        return false
    end
    if b[5] ~= 0x51 then -- version 0x51 (Lua 5.1)
        return false
    end
    return true
end

-- Reader over a byte string with endianness and size awareness
---@class R
---@field b string
---@field off integer
---@field little boolean
---@field sz_int integer
---@field sz_size_t integer
---@field sz_instr integer
---@field sz_lnum integer
local R = {}
R.__index = R

---@param b string
---@return R
local function new_reader(b)
    ---@type R
    local r = {
        b = b,
        off = 1,
        little = true,
        sz_int = 4,
        sz_size_t = 4,
        sz_instr = 4,
        sz_lnum = 8,
    }
    return setmetatable(r, R)
end

---@return integer
function R:pos()
    return self.off
end


---@param n integer
---@return string
function R:read_bytes(n)
    local s = self.b:sub(self.off, self.off + n - 1)
    self.off = self.off + n
    return s
end

---@param
---@return
function R:read_u8()
    local v = self.b:byte(self.off)
    self.off = self.off + 1
    return v
end

local function bytes_to_uint_le(s)
    local n = 0
    for i = 1, #s do
        n = n + s:byte(i) * (256 ^ (i - 1))
    end
    return n
end

local function bytes_to_uint_be(s)
    local n = 0
    local L = #s
    for i = 1, L do
        n = n * 256 + s:byte(i)
    end
    return n
end

function R:read_uint(nbytes)
    local s = self:read_bytes(nbytes)
    if self.little then
        return bytes_to_uint_le(s)
    else
        return bytes_to_uint_be(s)
    end
end

function R:read_int()
    return self:read_uint(self.sz_int)
end

function R:read_size_t()
    return self:read_uint(self.sz_size_t)
end

function R:read_instruction()
    return self:read_uint(self.sz_instr)
end

-- read lua_Number; try to decode as double if possible; otherwise return hex string
function R:read_lua_number()
    local s = self:read_bytes(self.sz_lnum)
    -- Attempt to use string.unpack if available
    local ok, num
    if string.unpack then
        if self.sz_lnum == 8 then
            if self.little then
                ok, num = pcall(string.unpack, "<d", s)
            else
                ok, num = pcall(string.unpack, ">d", s)
            end
        elseif self.sz_lnum == 4 then
            if self.little then
                ok, num = pcall(string.unpack, "<f", s)
            else
                ok, num = pcall(string.unpack, ">f", s)
            end
        end
    end
    if ok and type(num) == "number" then
        return num
    end
    -- Fallback: hex dump
    local hex = {}
    for i = 1, #s do
        hex[#hex + 1] = string.format("%02X", s:byte(i))
    end
    return "0x" .. table.concat(hex)
end


-- Constants reader
local function load_constant()
    local t = r:read_u8()
    push_range("const_type", 1)
    -- Lua 5.1 type tags align with TValue types: 0=nil, 1=boolean, 3=number, 4=string
    if t == 0 then
        return { type = "nil", value = nil }
    elseif t == 1 then
        local b = r:read_u8()
        push_range("const_bool", 1)
        return { type = "boolean", value = (b ~= 0) }
    elseif t == 3 then
        local n = r:read_lua_number()
        push_range("const_number", r.sz_lnum)
        return { type = "number", value = n }
    elseif t == 4 then
        local s = read_lua_string()
        return { type = "string", value = s }
    else
        return { type = string.format("unknown(%d)", t) }
    end
end

---@param bytes string
---@return Lua51DecodeResult
local function decode_all(bytes)
    local r = new_reader(bytes)

    local ranges = {}
    local function push_range(name, len)
        ranges[#ranges + 1] = { name = name, length = len }
    end

    -- Safety limits (can be overridden via Config)
    local cfg = Config.get() or {}
    local decode_cfg = (cfg.decode or {})
    local limits = (decode_cfg.limit or {})
    local MAX_PROTO_DEPTH = limits.max_proto_depth or 3
    local MAX_PROTOS_PER_FUNCTION = limits.max_protos_per_function or 3

    -- Header
    local sig = { r:read_u8(), r:read_u8(), r:read_u8(), r:read_u8() }
    push_range("signature", 4)
    local version = r:read_u8()
    push_range("version", 1)
    local format = r:read_u8()
    push_range("format", 1)
    local endian = r:read_u8()
    push_range("endian", 1)
    local size_int = r:read_u8()
    push_range("size_int", 1)
    local size_size_t = r:read_u8()
    push_range("size_size_t", 1)
    local size_instr = r:read_u8()
    push_range("size_instr", 1)
    local size_lua_num = r:read_u8()
    push_range("size_lua_num", 1)
    local integral_flag = r:read_u8()
    push_range("integral_flag", 1)

    -- LUAC_DATA (6 bytes) used for consistency check in lundump.c
    local luac_data = r:read_bytes(6)
    push_range("luac_data", 6)

    -- Configure reader sizes and endianness
    r.little = (endian == 1)
    r.sz_int = size_int
    r.sz_size_t = size_size_t
    r.sz_instr = size_instr
    r.sz_lnum = size_lua_num

    local result = {
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
    }

    -- utilities for string reading (Lua 5.1: size_t length including trailing NUL; 0 => nil)
    local function read_lua_string()
        local size = r:read_size_t()
        push_range("str_size", r.sz_size_t)
        if size == 0 then
            return nil
        end
        -- content includes trailing NUL; store content without NUL for readability
        local raw = r:read_bytes(size)
        push_range("str_bytes", size)
        if size > 0 then
            local content = raw:sub(1, size - 1)
            return content
        else
            return ""
        end
    end

    -- Forward declarations
    local load_function

    -- Constants reader
    local function load_constant()
        local t = r:read_u8()
        push_range("const_type", 1)
        -- Lua 5.1 type tags align with TValue types: 0=nil, 1=boolean, 3=number, 4=string
        if t == 0 then
            return { type = "nil", value = nil }
        elseif t == 1 then
            local b = r:read_u8()
            push_range("const_bool", 1)
            return { type = "boolean", value = (b ~= 0) }
        elseif t == 3 then
            local n = r:read_lua_number()
            push_range("const_number", r.sz_lnum)
            return { type = "number", value = n }
        elseif t == 4 then
            local s = read_lua_string()
            return { type = "string", value = s }
        else
            return { type = string.format("unknown(%d)", t) }
        end
    end

    -- Prototype reader (recursive)
    load_function = function(parent_source, depth)
        depth = (depth or 0)
        if depth > MAX_PROTO_DEPTH then
            error(
                string.format(
                    "Lua51 decode guard: max proto depth exceeded (%d > %d)",
                    depth,
                    MAX_PROTO_DEPTH
                )
            )
        end
        local src = read_lua_string()
        if not src then
            src = parent_source
        end
        local linedefined = r:read_int()
        push_range("linedefined", r.sz_int)
        local lastlinedefined = r:read_int()
        push_range("lastlinedefined", r.sz_int)
        local nupvalues = r:read_u8()
        push_range("nupvalues", 1)
        local numparams = r:read_u8()
        push_range("numparams", 1)
        local is_vararg = r:read_u8()
        push_range("is_vararg", 1)
        local maxstacksize = r:read_u8()
        push_range("maxstacksize", 1)

        -- code
        local sizecode = r:read_int()
        push_range("sizecode", r.sz_int)
        local code = {}
        local code_bytes_len = sizecode * r.sz_instr
        for i = 1, sizecode do
            local instr = r:read_instruction()
            code[i] = string.format("0x%0" .. (r.sz_instr * 2) .. "X", instr)
        end
        push_range("code", code_bytes_len)

        -- constants
        local sizek = r:read_int()
        push_range("sizek", r.sz_int)
        local consts = {}
        for i = 1, sizek do
            consts[i] = load_constant()
        end
        -- length was advanced internally by each field; we cannot aggregate reliably here for highlight gaps; keep contiguous by not pushing extra here

        -- protos (nested functions)
        local sizep = r:read_int()
        push_range("sizep", r.sz_int)
        if sizep > MAX_PROTOS_PER_FUNCTION then
            error(
                string.format(
                    "Lua51 decode guard: too many nested protos requested (%d > %d)",
                    sizep,
                    MAX_PROTOS_PER_FUNCTION
                )
            )
        end
        local protos = {}
        for i = 1, sizep do
            protos[i] = load_function(src, depth + 1)
        end

        -- debug: lineinfo, locvars, upvalue names
        local sizelineinfo = r:read_int()
        push_range("sizelineinfo", r.sz_int)
        local lineinfo = {}
        local lineinfo_bytes = sizelineinfo * r.sz_int
        for i = 1, sizelineinfo do
            lineinfo[i] = r:read_int()
        end
        push_range("lineinfo", lineinfo_bytes)

        local sizelocvars = r:read_int()
        push_range("sizelocvars", r.sz_int)
        local locvars = {}
        for i = 1, sizelocvars do
            local name = read_lua_string()
            local startpc = r:read_int()
            push_range("locvar.startpc", r.sz_int)
            local endpc = r:read_int()
            push_range("locvar.endpc", r.sz_int)
            locvars[i] = { name = name, startpc = startpc, endpc = endpc }
        end

        local sizeupvalues = r:read_int()
        push_range("sizeupvalues", r.sz_int)
        local upvalue_names = {}
        for i = 1, sizeupvalues do
            upvalue_names[i] = read_lua_string()
        end

        return {
            source = src,
            linedefined = linedefined,
            lastlinedefined = lastlinedefined,
            nupvalues = nupvalues,
            numparams = numparams,
            is_vararg = is_vararg,
            maxstacksize = maxstacksize,
            code = { count = sizecode, bytes = code },
            constants = { count = sizek, values = consts },
            protos = protos,
            debug = {
                sizelineinfo = sizelineinfo,
                lineinfo = lineinfo,
                sizelocvars = sizelocvars,
                locvars = locvars,
                sizeupvalues = sizeupvalues,
                upvalues = upvalue_names,
            },
        }
    end

    local proto = load_function(nil, 0)

    result.proto = proto
    result._undump_ranges = ranges
    return result
end

---@param Decode table  -- expects Decode.register(name, matcher, decoder)
function M.decode(Decode)
    Decode.register("lua51", is_lua51, function(bytes)
        return decode_all(bytes)
    end)
end

return M
