local t = require "tests.harness"
local Decode = require "undump.formatdecode"

-- Ensure builtin lua51 decoder is registered
require("undump.formatdecode.builtin.lua51").register(Decode)

t.testcase("lua51: decoder is registered", function()
    local names = Decode.list()
    t.assert_true(vim.tbl_contains(names, "lua51"))
end)

t.testcase("lua51: header decode produces expected fields", function()
    -- Construct minimal Lua 5.1 header bytes
    local bytes = string.char(
        0x1B,
        0x4C,
        0x75,
        0x61, -- signature ESC 'L' 'u' 'a'
        0x51, -- version 0x51 (Lua 5.1)
        0x00, -- format
        0x01, -- endianness (1 little)
        0x04, -- sizeof(int)
        0x08, -- sizeof(size_t)
        0x04, -- sizeof(Instruction)
        0x08, -- sizeof(lua_Number)
        0x00 -- integral flag (0 false)
    )

    local res = Decode.decode("bytecode.luac", bytes)
    t.assert_eq(type(res), "table")
    t.assert_eq(res.format, "Lua bytecode")
    t.assert_match(res.version, "5%.1")
    t.assert_eq(res.header.endianness, "little")
    t.assert_eq(res.header.sizeof_int, 4)
    t.assert_eq(res.header.sizeof_lua_Number, 8)
end)

t.testcase("lua51: non-matching bytes return no-match message", function()
    local res = Decode.decode("plain.bin", "hello")
    -- Depending on registry from other tests, it might be handled by other decoders
    -- Ensure that when lua51 does not match, we do not get a header table
    if type(res) == "table" and res.format == "Lua bytecode" then
        error "unexpected Lua bytecode decode for plain bytes"
    end
end)
