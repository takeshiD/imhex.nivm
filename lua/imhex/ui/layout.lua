local Config = require "imhex.config"
local HexView = require "imhex.ui.view_hex"
local AsciiView = require "imhex.ui.view_ascii"
local FormatView = require "imhex.ui.view_format"
local Decode = require "imhex.formatdecode"

local M = {}

---@class ImHexWins
---@field hex integer|nil
---@field ascii integer|nil
---@field format integer|nil

---@class ImHexBufs
---@field hex integer|nil
---@field ascii integer|nil
---@field format integer|nil

---@class ImHexLayoutState
---@field path string|nil
---@field bytes string|nil
---@field wins ImHexWins
---@field bufs ImHexBufs
---@field tab integer|nil

---@type ImHexLayoutState
local state = {
  path = nil,
  bytes = nil,
  wins = { hex = nil, ascii = nil, format = nil },
  bufs = { hex = nil, ascii = nil, format = nil },
  tab = nil,
}

---@param filetype? string
---@return integer
local function create_scratch_buffer(filetype)
  local buf = vim.api.nvim_create_buf(false, true)
  if filetype then
    vim.api.nvim_buf_set_option(buf, "filetype", filetype)
  end
  return buf
end

---@param path string
---@return string|nil data
---@return string? err
local function read_all_bytes(path)
  local fd = vim.loop.fs_open(path, "r", 438) -- 0666
  if not fd then
    return nil, "failed to open: " .. path
  end
  local stat = vim.loop.fs_fstat(fd)
  local data = vim.loop.fs_read(fd, stat.size, 0)
  vim.loop.fs_close(fd)
  if not data then
    return nil, "failed to read: " .. path
  end
  return data
end

---@return nil
local function ensure_layout()
  local cfg = Config.get()

  -- Create a new tabpage to isolate layout
  vim.cmd "tabnew"
  state.tab = vim.api.nvim_get_current_tabpage()
  local root = vim.api.nvim_get_current_win()

  -- bottom split for format view (spans full width)
  vim.cmd "belowright split"
  local win_bottom = vim.api.nvim_get_current_win()

  -- go to top (original root) and split vertically into hex + ascii
  vim.api.nvim_set_current_win(root)
  vim.cmd "vsplit"
  local win_ascii = vim.api.nvim_get_current_win()
  vim.cmd "wincmd h"
  local win_hex = vim.api.nvim_get_current_win()

  state.wins.hex = win_hex
  state.wins.ascii = win_ascii
  state.wins.format = win_bottom

  -- assign buffers
  state.bufs.hex = create_scratch_buffer "imhexhex"
  state.bufs.ascii = create_scratch_buffer "imhexascii"
  state.bufs.format = create_scratch_buffer "imhexformat"
  vim.api.nvim_win_set_buf(state.wins.hex, state.bufs.hex)
  vim.api.nvim_win_set_buf(state.wins.ascii, state.bufs.ascii)
  vim.api.nvim_win_set_buf(state.wins.format, state.bufs.format)

  -- sizing
  local total_height = vim.api.nvim_get_option "lines" - vim.o.cmdheight
  local bottom_h = math.max(3, math.floor(total_height * (1 - (cfg.ui.top_ratio or 0.7))))
  vim.api.nvim_win_set_height(state.wins.format, bottom_h)

  local total_width = vim.api.nvim_get_option "columns"
  local hex_w = math.floor(total_width * (cfg.ui.column_ratio or 0.55))
  vim.api.nvim_win_set_width(state.wins.hex, hex_w)
end

---@return nil
local function render_all()
  local cfg = Config.get()
  HexView.render(state.bufs.hex, state.bytes, { bytes_per_row = cfg.ui.bytes_per_row })
  AsciiView.render(state.bufs.ascii, state.bytes, { bytes_per_row = cfg.ui.bytes_per_row })

  local ok, result = pcall(function()
    return Decode.decode(state.path, state.bytes)
  end)
  if not ok then
    result = { "Decode error: " .. tostring(result) }
  end
  FormatView.render(state.bufs.format, result)
end

---@param path string
M.open = function(path)
  if not path or path == "" then
    vim.notify("[imhex] No file path provided", vim.log.levels.ERROR)
    return
  end
  local bytes, err = read_all_bytes(path)
  if not bytes then
    vim.notify("[imhex] " .. err, vim.log.levels.ERROR)
    return
  end
  state.path = path
  state.bytes = bytes
  ensure_layout()
  render_all()
end

---@return nil
M.close = function()
  if state.tab and vim.api.nvim_tabpage_is_valid(state.tab) then
    vim.cmd "tabclose"
  end
  state = {
    path = nil,
    bytes = nil,
    wins = { hex = nil, ascii = nil, format = nil },
    bufs = { hex = nil, ascii = nil, format = nil },
    tab = nil,
  }
end

---@param which 'hex'|'ascii'|'format'
M.toggle = function(which)
  local win = state.wins[which]
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end
  local cfg = Config.get()
  local show_key = {
    hex = "show_hex",
    ascii = "show_ascii",
    format = "show_format",
  }
  local flag_key = show_key[which]
  cfg.ui[flag_key] = not cfg.ui[flag_key]
  if cfg.ui[flag_key] then
    vim.api.nvim_win_set_config(win, { hide = false })
    vim.api.nvim_win_set_option(win, "winhighlight", "")
  else
    -- dim and wipe content
    vim.api.nvim_buf_set_lines(state.bufs[which], 0, -1, false, { "[" .. which .. " hidden ]" })
    vim.api.nvim_win_set_option(win, "winhighlight", "Normal:Folded")
  end
end

return M
