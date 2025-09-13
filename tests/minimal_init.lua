-- Minimal init for headless testing
-- Sets up runtimepath and package.path to load the plugin from this repo

local cwd = vim.fn.getcwd()

-- Keep our repo at the front of runtimepath so plugin/ loads if needed
vim.opt.runtimepath:prepend(cwd)

-- Make Lua modules under lua/ discoverable
package.path = table.concat({
    cwd .. "/lua/?.lua",
    cwd .. "/lua/?/init.lua",
    cwd .. "/tests/?.lua",
    cwd .. "/tests/?/init.lua",
    package.path,
}, ";")

-- Reduce noise and avoid external providers
vim.g.loaded_python_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

vim.o.swapfile = false
vim.o.shadafile = ""
