local t = require "tests.harness"
local Config = require "undump.config"
local Decode = require "undump.formatdecode"

t.testcase("formatdecode: fallback when no decoders", function()
    -- Reset config to defaults; registry is empty at process start
    Config.setup(nil)
    local res = Decode.decode("no-match-path.bin", "abc")
    t.assert_eq(type(res), "table")
    t.assert_match(res[1], "No decoder matched")
end)

t.testcase("formatdecode: register and list decoders", function()
    Decode.register("foo", function(_bytes, path)
        return path:sub(-9) == ".foo-test"
    end, function(bytes, path)
        return { kind = "foo", size = #bytes, path = path }
    end)
    local names = Decode.list()
    t.assert_true(vim.tbl_contains(names, "foo"))
    local res = Decode.decode("sample.foo-test", "abcdef")
    t.assert_eq(type(res), "table")
    t.assert_eq(res.kind, "foo")
    t.assert_eq(res.size, 6)
end)

t.testcase("formatdecode: prefer order applied when multiple match", function()
    Decode.register("bar", function(_bytes, path)
        return path == "prefer-case"
    end, function(_bytes)
        return { kind = "bar" }
    end)
    Decode.register("foo2", function(_bytes, path)
        return path == "prefer-case"
    end, function(_bytes)
        return { kind = "foo2" }
    end)
    Config.setup { decode = { prefer = { "bar", "foo2" } } }
    local res = Decode.decode("prefer-case", "xyz")
    t.assert_eq(res.kind, "bar")
end)
