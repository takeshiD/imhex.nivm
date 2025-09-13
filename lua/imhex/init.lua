---@class ImHex
local M = {}

local Config = require "imhex.config"
local UI = require "imhex.ui"
local Decode = require "imhex.formatdecode"

--- Public setup entrypoint
---@param opts? ImHexConfig
M.setup = function(opts)
  Config.setup(opts)

  -- Register built-in decoders
  require("imhex.formatdecode.builtin.lua51").register(Decode)

  -- Define user commands
  if vim and vim.api then
    vim.api.nvim_create_user_command("ImHexOpen", function(params)
      local path = params.args ~= "" and params.args or vim.api.nvim_buf_get_name(0)
      UI.open(path)
    end, { nargs = "?", complete = "file" })

    vim.api.nvim_create_user_command("ImHexClose", function()
      UI.close()
    end, {})
  end
end

return M
