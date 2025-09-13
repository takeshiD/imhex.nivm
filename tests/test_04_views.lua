local t = require "tests.harness"

local HexView = require "undump.ui.view_hex"
local AsciiView = require "undump.ui.view_ascii"
local FormatView = require "undump.ui.view_format"

---@return integer
local function new_scratch()
    return vim.api.nvim_create_buf(false, true)
end

t.testcase("hex view: renders bytes into lines", function()
    local buf = new_scratch()
    HexView.render(buf, "ABC", { bytes_per_row = 8 })
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    t.assert_true(#lines >= 1)
    t.assert_match(lines[1], "^00000000  41 42 43")
end)

t.testcase("ascii view: renders printable and dot mask", function()
    local buf = new_scratch()
    AsciiView.render(buf, string.char(65, 9, 66), { bytes_per_row = 8 })
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    t.assert_true(#lines >= 1)
    -- Expect 'A' then non-printable -> '.' then 'B'
    t.assert_match(lines[1], "00000000  A.B")
end)

t.testcase("format view: renders table and string inputs", function()
    local buf1 = new_scratch()
    FormatView.render(buf1, { a = 1, b = { 2, 3 } })
    local l1 = vim.api.nvim_buf_get_lines(buf1, 0, -1, false)
    t.assert_true(#l1 >= 2)

    local buf2 = new_scratch()
    FormatView.render(buf2, "line1\nline2")
    local l2 = vim.api.nvim_buf_get_lines(buf2, 0, -1, false)
    t.assert_eq(l2[1], "line1")
    t.assert_eq(l2[2], "line2")
end)
