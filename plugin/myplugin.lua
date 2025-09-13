if vim.g.loaded_myplugin == 1 then
  return
end
vim.g.loaded_myplugin = 1

local ok, myplugin = pcall(require, "myplugin")
if not ok then
  return
end

-- initialize with defaults; user may call require('myplugin').setup in config
if not myplugin._initialized then
  myplugin.setup()
  myplugin._initialized = true
end

-- Simple example user command
vim.api.nvim_create_user_command("MyPluginHello", function()
  require("myplugin").hello()
end, { desc = "MyPlugin: show hello notification" })

