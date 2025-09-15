local DecoderLua51 = require("undump.formatdecode.builtin.lua51")
---@class UndumpUiConfig
---@field top_ratio number  -- top area (hex+ascii) height ratio
---@field column_ratio number  -- hex:ascii width ratio
---@field bytes_per_row integer
---@field show_ascii boolean
---@field show_hex boolean
---@field show_format boolean

---@class UndumpDecodeLimit
---@field max_proto_depth integer?
---@field max_protos_per_function integer?

---@class UndumpDecodeConfig
---@field prefer string[]  -- order matters; first matching decoder wins
---@field decoders table<string, UndumpDecoder>
---@field limit UndumpDecodeLimit?

---@class UndumpConfig
---@field ui UndumpUiConfig
---@field decode UndumpDecodeConfig

---@class UndumpConfigState
---@field config UndumpConfig

local M = {}

---@type UndumpConfig
local defaults = {
    ui = {
        top_ratio = 0.7, -- top area (hex+ascii) height ratio
        column_ratio = 0.55, -- hex:ascii width ratio (hex wider)
        bytes_per_row = 16,
        show_ascii = true,
        show_hex = true,
        show_format = true,
    },
    decode = {
        -- order matters; first matching decoder wins
        prefer = { "lua51" },
        decoders = {
            DecoderLua51,
        },
    },
}

---@type UndumpConfigState
local state = {
    config = vim.deepcopy(defaults),
}

---@generic T: table
---@param dst T
---@param src T|nil
---@return T
local function deep_merge(dst, src)
    for k, v in pairs(src or {}) do
        if type(v) == "table" and type(dst[k]) == "table" then
            deep_merge(dst[k], v)
        else
            dst[k] = v
        end
    end
    return dst
end

---@param opts? UndumpConfig
M.setup = function(opts)
    state.config = deep_merge(vim.deepcopy(defaults), opts or {})
end

---@return UndumpConfig
M.get = function()
    return state.config
end

return M
