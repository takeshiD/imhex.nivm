---@class UndumpNotify
local M = {}

NOTIFY_HEAD = "[undump.nvim] "

---@class UndumpNotifyOpts
---@field level vim.log.levels

---@param msg string
---@param opts? UndumpNotifyOpts
M.notify = function(msg, opts)
    if msg == nil then
        return
    end
    opts = opts or {}
    vim.notify(NOTIFY_HEAD .. msg, opts.level)
end

---@param msg string
M.warn = function(msg, ...)
    M.notify(string.format(msg, ...), { level = vim.log.levels.WARN })
end

---@param msg string
M.info = function(msg, ...)
    M.notify(string.format(msg, ...), { level = vim.log.levels.INFO })
end

---@param msg string
M.error = function(msg, ...)
    M.notify(string.format(msg, ...), { level = vim.log.levels.ERROR })
end

---@param msg string
M.debug = function(msg, ...)
    M.notify(string.format(msg, ...), { level = vim.log.levels.DEBUG })
end

return M
