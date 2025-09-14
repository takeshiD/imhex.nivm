---@class UndumpUtils
local M = {}

---@param prefix string
---@return boolean
function string:startswith(prefix)
    return self.sub(1, #prefix) == prefix
end

