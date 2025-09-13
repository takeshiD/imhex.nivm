---@class UndumpUI
local M = {}

local layout = require "undump.ui.layout"

---@param path string
M.open = function(path)
    layout.open(path)
end

---@return nil
M.close = function()
    layout.close()
end

---@return nil
M.toggle_hex = function()
    layout.toggle "hex"
end

---@return nil
M.toggle_ascii = function()
    layout.toggle "ascii"
end

---@return nil
M.toggle_format = function()
    layout.toggle "format"
end

return M
