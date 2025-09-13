local M = {}

local function to_hex(byte)
  return string.format("%02X", byte)
end

local function build_lines(bytes, bytes_per_row)
  local lines = {}
  local len = #bytes
  local offset = 0
  while offset < len do
    local row_bytes = {}
    for i = 1, bytes_per_row do
      local idx = offset + i
      if idx <= len then
        row_bytes[#row_bytes + 1] = to_hex(bytes:byte(idx))
      else
        row_bytes[#row_bytes + 1] = "  "
      end
    end
    local addr = string.format("%08X", offset)
    lines[#lines + 1] = addr .. "  " .. table.concat(row_bytes, " ")
    offset = offset + bytes_per_row
  end
  return lines
end

M.render = function(buf, bytes, opts)
  local bpr = (opts and opts.bytes_per_row) or 16
  local lines = build_lines(bytes or "", bpr)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

return M
