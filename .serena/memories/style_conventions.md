# Style & Conventions

- Formatting: Stylua (`stylua.toml` present). Prefer single-quoted strings in UI `init.lua`, mixed acceptable; Stylua will normalize.
- Types: lua-language-server (EmmyLua) annotations used throughout:
  - `---@class`, `---@field`, `---@alias`, `---@param`, `---@return`, `---@type`, and generics via `---@generic`.
  - Module tables documented with a `---@class` above `local M = {}`.
  - Structured tables documented via `---@class` and applied via `---@type` where instantiated.
- Naming: Modules under `imhex.*`. Functions are mostly `M.method = function(...) end` or `local function name(...)`.
- Neovim handles: buffer/window/tabpage are `integer`.
- Decoders API:
  - `Decode.register(name: string, matcher: fun(bytes, path): boolean, decoder: fun(bytes, path): table|string)`
  - Registry holds `ImHexDecoder[]`.
