# Task Completion Checklist

- Add lua-language-server type annotations to all functions and class-like tables.
- Verify local functions and exported `M.*` have `---@param`/`---@return` as appropriate.
- Document structured state/config tables via `---@class` and `---@type`.
- Run `stylua .` to normalize formatting.
- Optionally run tests to ensure behavior unchanged:
  nvim --headless -u tests/minimal_init.lua -c 'luafile tests/runner.lua'
