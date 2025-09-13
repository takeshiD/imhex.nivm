# Suggested Commands

- Run tests (Neovim headless):
  nvim --headless -u tests/minimal_init.lua -c 'luafile tests/runner.lua'

- Format with Stylua (if installed locally):
  stylua .

- Basic grep for functions needing types:
  rg -n "^\s*local\s+function|=\s*function\s*\(|M\.[a-zA-Z_]+\s*=\s*function" -g "*.lua"

- Open health check in Neovim:
  :checkhealth myplugin
