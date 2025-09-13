local Config = require "imhex.config"

local M = {}

local registry = {}

-- Register a decoder
-- name: string
-- matcher: function(bytes, path) -> boolean
-- decoder: function(bytes, path) -> table|string (decoded result)
M.register = function(name, matcher, decoder)
  registry[#registry + 1] = { name = name, match = matcher, decode = decoder }
end

M.list = function()
  local names = {}
  for _, d in ipairs(registry) do
    names[#names + 1] = d.name
  end
  return names
end

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
