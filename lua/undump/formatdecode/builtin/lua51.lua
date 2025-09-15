---@class Lua51Decoder: UndumpDecoder

---@class Lua51DecodedResult
---@field header Lua51Header
---@field proto Lua51Proto

---@class Lua51Header
---@field signature string
---@field lua_version string
---@field format_version integer
---@field endianness string
---@field sizeof_int integer
---@field sizeof_size_t integer
---@field sizeof_inst integer
---@field sizeof_number integer
---@field number_integral boolean

---@class Lua51Proto
---@field name string
---@field first_line integer
---@field last_line integer
---@field num_upval integer
---@field num_param integer
---@field is_vararg integer
---@field maxstacksize integer
---@field instructions Lua51Instruction[]
---@field constants Lua51Constant[]
---@field protos Lua51Proto[]
---@field debug Lua51Debug

---@class Lua51Instruction

---@class Lua51Constant
---@field value any

---@class Lua51Debug
---@field lines integer[]
---@field locals any
---@field upvalues any

---@type Lua51Decoder
local M

---@type string
M.name = "lua51"

---@private
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

---@param bytes string
---@param path string
---@return boolean
function M.matcher(bytes, path)
    return is_lua51(bytes)
end

---@param bytes string
---@param path string
---@return Lua51DecodedResult
function M.decoder(bytes, path)
    return {}
end

return M
