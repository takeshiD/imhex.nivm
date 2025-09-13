---@class Undump
local M = {}

local Config = require "undump.config"
local UI = require "undump.ui"
local Decode = require "undump.formatdecode"

--- Public setup entrypoint
---@param opts? UndumpConfig
M.setup = function(opts)
    Config.setup(opts)

    -- Register built-in decoders
    require("undump.formatdecode.builtin.lua51").register(Decode)

    -- Define user commands
    if vim and vim.api then
        vim.api.nvim_create_user_command("UndumpOpen", function(params)
            local path = params.args ~= "" and params.args or vim.api.nvim_buf_get_name(0)
            UI.open(path)
        end, { nargs = "?", complete = "file" })

        vim.api.nvim_create_user_command("UndumpClose", function()
            UI.close()
        end, {})
    end
end

return M
