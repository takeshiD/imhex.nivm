local Config = require "imhex.config"

---@alias ImHexDecoded table|string

---@class ImHexDecoder
---@field name string
---@field match fun(bytes: string, path: string): boolean
---@field decode fun(bytes: string, path: string): ImHexDecoded

local M = {}

---@type ImHexDecoder[]
local registry = {}

--- Register a decoder
---@param name string
---@param matcher fun(bytes: string, path: string): boolean
---@param decoder fun(bytes: string, path: string): ImHexDecoded
M.register = function(name, matcher, decoder)
  registry[#registry + 1] = { name = name, match = matcher, decode = decoder }
end

---@return string[]
M.list = function()
  local names = {}
  for _, d in ipairs(registry) do
    names[#names + 1] = d.name
  end
  return names
end

---@param path string
---@param bytes string
---@return ImHexDecoder|nil
local function pick_decoder(path, bytes)
  local cfg = Config.get()
  -- First, try preferred decoders if they match
  local preferred = {}
  for _, d in ipairs(registry) do
    preferred[d.name] = d
  end
  for _, name in ipairs(cfg.decode.prefer or {}) do
    local d = preferred[name]
    if d and d.match(bytes, path) then
      return d
    end
  end
  -- Fallback: first matching
  for _, d in ipairs(registry) do
    if d.match(bytes, path) then
      return d
    end
  end
  return nil
end

---@param path string
---@param bytes string
---@return ImHexDecoded
M.decode = function(path, bytes)
  local d = pick_decoder(path, bytes)
  if not d then
    return { "No decoder matched. Registered: " .. table.concat(M.list(), ", ") }
  end
  local ok, result = pcall(d.decode, bytes, path)
  if not ok then
    return { "Decoder error [" .. d.name .. "]: " .. tostring(result) }
  end
  return result
end

return M
