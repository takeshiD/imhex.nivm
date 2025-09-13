local M = {}

function M.check()
  vim.health.start("myplugin")

  if vim.fn.has("nvim-0.8") == 1 then
    vim.health.ok("Neovim 0.8+ detected")
  else
    vim.health.warn("Neovim 0.8+ is recommended")
  end

  local ok = pcall(require, "myplugin")
  if ok then
    vim.health.ok("myplugin module loads correctly")
  else
    vim.health.error("myplugin module failed to load")
  end
end

return M

