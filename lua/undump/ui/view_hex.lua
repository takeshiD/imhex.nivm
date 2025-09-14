local Notify = require("undump.notify")
local Highlight = require("undump.highlight")

---@class UndumpHexView
local M = {}

---@class UndumpRenderOpts
---@field bytes_per_row integer

local NS_HEX = vim.api.nvim_create_namespace("undump.hex")

local function ensure_default_hl()
    -- Define a default pink background for signature if not present
    for _, v in pairs(Highlight.highlights) do
        local hl_name = v.name
        local hl_bg = v.bg
        local ok = pcall(vim.api.nvim_get_hl, 0, { name = hl_name })
        if ok then
            local signature_hl = vim.api.nvim_get_hl(0, { name = hl_name })
            if signature_hl then
                vim.api.nvim_set_hl(0, hl_name, { bg = hl_bg })
            else
                Notify.warn("failed set highlight %s", hl_name)
            end
        else
            vim.api.nvim_set_hl(0, hl_name, { bg = hl_bg })
        end
    end
end

---@param byte integer
---@return string
local function to_hex(byte)
    return string.format("%02X", byte)
end

---@param bytes string
---@param bytes_per_row integer
---@return string[]
local function build_lines(bytes, bytes_per_row)
    local lines = {}
    local len = #bytes
    local offset = 0
    while offset < len do
        local row_bytes = {}
        for i = 1, bytes_per_row do
            local idx = offset + i
            if idx <= len then
                row_bytes[#row_bytes + 1] = to_hex(bytes:byte(idx))
            else
                row_bytes[#row_bytes + 1] = "  "
            end
        end
        local addr = string.format("%08X", offset)
        lines[#lines + 1] = addr .. "  " .. table.concat(row_bytes, " ")
        offset = offset + bytes_per_row
    end
    return lines
end

---@param buf integer
---@param bytes string|nil
---@param opts UndumpRenderOpts|nil
M.render = function(buf, bytes, opts)
    local bpr = (opts and opts.bytes_per_row) or 16
    local lines = build_lines(bytes or "", bpr)
    -- ensure buffer can be updated (use buf-local API for compatibility)
    vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

---Apply highlights to the hex view according to decoded metadata.
---@param buf integer buffer handle of hex view
---@param decoded any decoder result; expects optional field `_undump_ranges`
---@param opts UndumpRenderOpts|nil
M.highlight = function(buf, decoded, opts)
    if type(decoded) ~= "table" then
        return
    end
    local ranges = decoded._undump_ranges
    if not vim.islist(ranges) or #ranges == 0 then
        -- nothing to highlight
        vim.api.nvim_buf_clear_namespace(buf, NS_HEX, 0, -1)
        return
    end

    ensure_default_hl()

    local bpr = (opts and opts.bytes_per_row) or 16
    -- Clear existing
    vim.api.nvim_buf_clear_namespace(buf, NS_HEX, 0, -1)

    -- Column math: "AAAAAAAA  XX XX ..."
    -- Address (8) + two spaces => first hex starts at col 10 (0-based index).
    local base_col = 10

    ---@param byte_index_1 integer
    ---@param span integer
    ---@param hl string
    local function add_byte_hl(byte_index_1, span, hl)
        local idx0 = byte_index_1 - 1
        local row = math.floor(idx0 / bpr)
        local col = base_col + (idx0 % bpr) * 3
        -- highlight two hex chars
        vim.hl.range(buf, NS_HEX, hl, { row, col }, { row, col + span })
    end

    local start = 1
    local hl_num = 1
    for _, r in ipairs(ranges) do
        local len = r.length
        local hl = string.format("UndumpHexSignature%d", hl_num)
        if len > 0 then
            for i = 0, len - 1 do
                if i == len - 1 then
                    add_byte_hl(start + i, 2, hl)
                else
                    add_byte_hl(start + i, 3, hl)
                end
            end
        end
        start = start + len
        hl_num = ((hl_num + 1) % 7) + 1
    end
end

return M
