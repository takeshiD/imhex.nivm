---@alias UndumpDecodedResult table|string

---@class UndumpDecoder
---@field name string
---@field matcher fun(bytes: string, path: string): boolean
---@field decoder fun(bytes: string, path: string): UndumpDecodedResult

local M = {}

---@private
---@param decoders UndumpDecoder[]
---@param prefer string[]
---@param path string
---@param bytes string
---@return UndumpDecoder|nil
local function pick_decoder(decoders, prefer, path, bytes)
    -- First, try preferred decoders if they match
    ---@type table<string, UndumpDecoder>
    local preferred = {}
    for _, d in ipairs(decoders) do
        preferred[d.name] = d
    end
    for _, name in ipairs(prefer or {}) do
        local d = preferred[name]
        if d and d.matcher(bytes, path) then
            return d
        end
    end
    -- Fallback: first matching
    for _, d in ipairs(decoders) do
        if d.matcher(bytes, path) then
            return d
        end
    end
    return nil
end

---@param decoders UndumpDecoder[]
---@param prefer string[]
---@param path string
---@param bytes string
---@return UndumpDecodedResult
---Interface for format decoder
M.decode = function(decoders, prefer, path, bytes)
    local d = pick_decoder(decoders, prefer, path, bytes)
    if not d then
        return { "No decoder matched. Registered: " .. table.concat(M.list(), ", ") }
    end
    local ok, result = pcall(d.decoder, bytes, path)
    if not ok then
        return { "Decoder error [" .. d.name .. "]: " .. tostring(result) }
    end
    return result
end

return M
