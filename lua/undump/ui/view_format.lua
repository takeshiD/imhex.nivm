---@class UndumpFormatView
local M = {}

---@param lines string[]
---@param level integer
---@return string[]
local function indent_lines(lines, level)
    local pad = string.rep("  ", level)
    local out = {}
    for _, l in ipairs(lines) do
        out[#out + 1] = pad .. l
    end
    return out
end

---@param tbl table
---@param level integer|nil
---@return string[]
local function render_table(tbl, level)
    level = level or 0
    local lines = {}
    if vim.tbl_islist(tbl) then
        for _, v in ipairs(tbl) do
            if type(v) == "table" then
                vim.list_extend(lines, render_table(v, level))
            else
                lines[#lines + 1] = tostring(v)
            end
        end
    else
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                lines[#lines + 1] = tostring(k) .. ": "
                vim.list_extend(lines, indent_lines(render_table(v, level + 1), 1))
            else
                lines[#lines + 1] = tostring(k) .. ": " .. tostring(v)
            end
        end
    end
    return lines
end

---@param buf integer
---@param decoded string|string[]|table
M.render = function(buf, decoded)
    local lines
    if type(decoded) == "string" then
        lines = vim.split(decoded, "\n", { plain = true })
    elseif type(decoded) == "table" then
        lines = render_table(decoded)
    else
        lines = { tostring(decoded) }
    end
    if #lines == 0 then
        lines = { "[no decoded data]" }
    end
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

return M
