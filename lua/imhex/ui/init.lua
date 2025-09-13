local M = {}

local layout = require('imhex.ui.layout')

M.open = function(path)
    layout.open(path)
end

M.close = function()
    layout.close()
end

M.toggle_hex = function()
    layout.toggle('hex')
end

M.toggle_ascii = function()
    layout.toggle('ascii')
end

M.toggle_format = function()
    layout.toggle('format')
end

return M

