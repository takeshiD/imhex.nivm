-- Simple test runner that discovers and executes tests/* files

local uv = vim.loop

local function is_test_file(name)
  return name:match("^test_.*%.lua$") ~= nil
end

local function scan_tests()
  local dir = "tests"
  local entries = {}
  local iter, dirh = uv.fs_scandir(dir)
  if not iter then
    error("cannot scan tests directory")
  end
  while true do
    local name = uv.fs_scandir_next(dirh)
    if not name then
      break
    end
    if is_test_file(name) then
      table.insert(entries, name)
    end
  end
  table.sort(entries)
  local paths = {}
  for _, n in ipairs(entries) do
    table.insert(paths, dir .. "/" .. n)
  end
  return paths
end

-- load tests to register cases
for _, path in ipairs(scan_tests()) do
  dofile(path)
end

-- run them
require("tests.harness").run()

