---@class TestCase
---@field name string
---@field fn fun()

---@class Harness
---@field cases TestCase[]
local M = {}

---@type TestCase[]
M.cases = {}

---@param name string
---@param fn fun()
function M.testcase(name, fn)
    table.insert(M.cases, { name = name, fn = fn })
end

---@param v any
---@return string
local function as_str(v)
    if type(v) == "string" then
        return v
    end
    if vim and vim.inspect then
        return vim.inspect(v)
    end
    return tostring(v)
end

---@param cond boolean
---@param msg? string
function M.assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

---@param a any
---@param b any
---@param msg? string
function M.assert_eq(a, b, msg)
    if a ~= b then
        error(
            (msg and (msg .. "\n") or "")
                .. "expected ==, got\nleft: "
                .. as_str(a)
                .. "\nright: "
                .. as_str(b)
        )
    end
end

---@param s string
---@param pat string
---@param msg? string
function M.assert_match(s, pat, msg)
    if type(s) ~= "string" then
        error("assert_match: not a string: " .. as_str(s))
    end
    if not string.find(s, pat) then
        error((msg or "pattern not found") .. ": " .. pat .. " in " .. s)
    end
end

---@return nil
function M.run()
    local passed, failed = 0, 0
    for _, c in ipairs(M.cases) do
        local ok, err = pcall(c.fn)
        if ok then
            passed = passed + 1
            print(string.format("[PASS] %s", c.name))
        else
            failed = failed + 1
            print(string.rep("-", 60))
            print(string.format("[FAIL] %s", c.name))
            print(err)
            print(string.rep("-", 60))
        end
    end
    print(string.format("Summary: %d passed, %d failed", passed, failed))
    if failed > 0 then
        vim.cmd "cq 1"
    else
        vim.cmd "qall"
    end
end

return M
