-- Integration test: multiple concurrent FS operations via libuv
local ok_uv, uv = pcall(require, "rmp.uv")

if not ok_uv then
    print("=== Skipping libuv fs tests: rmp.uv not available ===")
    os.exit(0)
end

local test_count = 0
local pass_count = 0

local function test(name, fn)
    test_count = test_count + 1
    io.write("Test " .. name .. ": ")
    local ok, err = pcall(fn)
    if ok then
        pass_count = pass_count + 1
        print("PASS")
    else
        print("FAIL - " .. err)
    end
end

local function assert_equal(actual, expected, msg)
    msg = msg or "Values should be equal"
    if actual ~= expected then
        error(msg .. " (got: " .. tostring(actual) .. ", expected: " .. tostring(expected) .. ")")
    end
end

local function assert_true(condition, msg)
    msg = msg or "Condition should be true"
    if not condition then
        error(msg)
    end
end

print("=== Running libuv FS Integration Tests ===\n")

test("write/read multiple files", function()
    local files = {}
    local payloads = {}
    local results = {}
    local pending = 3

    for i = 1, 3 do
        local tmp = os.tmpname() .. "_uv_" .. tostring(i)
        files[i] = tmp
        payloads[i] = "payload_" .. tostring(i)
    end

    for i = 1, 3 do
        uv.fs_writefile(files[i], payloads[i], function(err, bytes)
            assert_equal(err, nil)
            assert_equal(bytes, #payloads[i])
            uv.fs_readfile(files[i], function(err2, data)
                assert_equal(err2, nil)
                results[i] = data
                pending = pending - 1
            end)
        end)
    end

    uv.run("default")

    for i = 1, 3 do
        os.remove(files[i])
        assert_equal(results[i], payloads[i])
    end

    assert_true(pending == 0, "not all callbacks completed")
end)

print("\n=== libuv FS Integration Tests: " .. pass_count .. "/" .. test_count .. " passed ===")
