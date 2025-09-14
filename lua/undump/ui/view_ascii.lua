local Highlight = require("undump.highlight")

---@class UndumpAsciiView
local M = {}

local NS_ASCII = vim.api.nvim_create_namespace("undump.ascii")

local function ensure_default_hl()
    for _, v in pairs(Highlight.highlights) do
        local hl_name = v.name
        local hl_bg = v.bg
        local ok = pcall(vim.api.nvim_get_hl, 0, { name = hl_name })
        if ok then
            local existed = vim.api.nvim_get_hl(0, { name = hl_name })
            if existed then
                vim.api.nvim_set_hl(0, hl_name, { bg = hl_bg })
            end
        else
            vim.api.nvim_set_hl(0, hl_name, { bg = hl_bg })
        end
    end
end

---@param byte integer
---@return string
local function to_ascii(byte)
    if byte >= 32 and byte <= 126 then
        return string.char(byte)
    else
        return "."
    end
end

---@param bytes string
---@param bytes_per_row integer
---@return string[]
local function build_lines(bytes, bytes_per_row)
    local lines = {}
    local len = #bytes
    local offset = 0
    while offset < len do
        local row_chars = {}
        for i = 1, bytes_per_row do
            local idx = offset + i
            if idx <= len then
                row_chars[#row_chars + 1] = to_ascii(bytes:byte(idx))
            else
                row_chars[#row_chars + 1] = " "
            end
        end
        lines[#lines + 1] = table.concat(row_chars)
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
    vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

---Apply highlights to the ascii view according to decoded metadata.
---@param buf integer buffer handle of ascii view
---@param decoded any decoder result; expects optional field `_undump_ranges`
---@param opts UndumpRenderOpts|nil
M.highlight = function(buf, decoded, opts)
    if type(decoded) ~= "table" then
        return
    end
    local ranges = decoded._undump_ranges
    if not vim.islist(ranges) or #ranges == 0 then
        vim.api.nvim_buf_clear_namespace(buf, NS_ASCII, 0, -1)
        return
    end

    ensure_default_hl()

    local bpr = (opts and opts.bytes_per_row) or 16
    vim.api.nvim_buf_clear_namespace(buf, NS_ASCII, 0, -1)

    ---@param byte_index_1 integer
    ---@param hl string
    local function add_char_hl(byte_index_1, hl)
        local idx0 = byte_index_1 - 1
        local row = math.floor(idx0 / bpr)
        local col = idx0 % bpr
        vim.hl.range(buf, NS_ASCII, hl, { row, col }, { row, col + 1 })
    end

    local start = 1
    local hl_num = 1
    for _, r in ipairs(ranges) do
        local len = r.length
        local hl = string.format("UndumpHexSignature%d", hl_num)
        if len > 0 then
            for i = 0, len - 1 do
                add_char_hl(start + i, hl)
            end
        end
        start = start + len
        hl_num = ((hl_num + 1) % 7) + 1
    end
end

return M
