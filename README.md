# myplugin.nvim

Minimal Lua-based Neovim plugin starter.

## Features

- `lua/myplugin/` module with `setup()` and example function
- `plugin/myplugin.lua` auto-load on startup (creates `:MyPluginHello`)
- `doc/myplugin.txt` Vim help skeleton (run `:helptags doc`)
- `health/myplugin.lua` for `:checkhealth myplugin`
- `stylua.toml` for code formatting

## Quick Start

1. Install with your plugin manager (example: lazy.nvim):

   ```lua
   {
     "yourname/myplugin.nvim",
     config = function()
       require("myplugin").setup({})
     end,
   }
   ```

2. Restart Neovim, then try:

   - `:MyPluginHello` — shows a hello notification
   - `:checkhealth myplugin` — runs basic health checks

## Rename The Plugin

If you want a different module name:

- Rename directory `lua/myplugin/` to `lua/<newname>/`
- Rename file `plugin/myplugin.lua` to `plugin/<newname>.lua`
- Replace `myplugin` occurrences in the repo (module name, docs, commands)

## Development

- Format with `stylua`: `stylua .`
- Update help tags after editing `doc/myplugin.txt`: `:helptags doc`

## License

Choose a license and add it to the repository (e.g. MIT). This starter ships without a license file by default.

