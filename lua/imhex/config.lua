local M = {}

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
        prefer = { 'lua51' },
    },
}

local state = {
    config = vim.deepcopy(defaults),
}

local function deep_merge(dst, src)
    for k, v in pairs(src or {}) do
        if type(v) == 'table' and type(dst[k]) == 'table' then
            deep_merge(dst[k], v)
        else
            dst[k] = v
        end
    end
    return dst
end

M.setup = function(opts)
    state.config = deep_merge(vim.deepcopy(defaults), opts or {})
end

M.get = function()
    return state.config
end

return M

