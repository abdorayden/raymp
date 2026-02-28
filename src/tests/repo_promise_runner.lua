-- local Promise = dofile("../promises.lua")
local Promise = require("rmp.promises")

local repo_url = "https://github.com/abdorayden/rose-pine-theme-rmp.git"
local dest_dir = "/tmp/rose-pine-theme-rmp-" .. tostring(os.time())

local buffer = ""
local percent = 0
local stage = "cloning"
local done = false
local result = nil
local err_result = nil

local function render()
    io.write(string.format("\rGit clone: %3d%% %s", percent, stage))
    io.flush()
end

local function handle_line(line)
    if line:find("Receiving objects") then
        stage = "receiving"
    elseif line:find("Resolving deltas") then
        stage = "resolving"
    elseif line:find("Checking out files") then
        stage = "checkout"
    end

    local p = line:match("(%d+)%%")
    if p then
        percent = tonumber(p) or percent
    end
end

Promise.spawn("git", {
    args = { "clone", "--progress", repo_url, dest_dir },
    on_stderr = function(chunk)
        buffer = buffer .. chunk
        while true do
            local s, e = buffer:find("[\r\n]")
            if not s then
                break
            end
            local line = buffer:sub(1, s - 1)
            buffer = buffer:sub(e + 1)
            if #line > 0 then
                handle_line(line)
            end
        end
    end
})
    :tthen(function(res)
        result = res
        done = true
    end)
    :catch(function(err)
        err_result = err
        done = true
    end)

local last_render = 0
while not done do
    Promise.runner()
    local now = os.clock()
    if now - last_render > 0.05 then
        render()
        last_render = now
    end
end

render()
io.write("\n")
if err_result then
    print("git clone failed:", err_result)
else
    print("git clone done, status:", result and result.status or "?")
    print("output dir:", dest_dir)
end
