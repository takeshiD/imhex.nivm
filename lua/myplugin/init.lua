local M = {}

M.opts = {
  option = true,
}

---Setup myplugin with user options
---@param opts table|nil
function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
end

---Example function
function M.hello()
  vim.notify("myplugin: hello from Lua!", vim.log.levels.INFO)
end

return M

