-- AOHarness: dev-only CET mod that lets tools/cet.ps1 run Lua inside the running game.
--
-- tools/cet.ps1 writes cmd.lua into this folder with a first line "-- id: <n>". Every half
-- second the harness checks it; when the id is new it runs the code and appends the result to
-- out.log between "@@begin <n>" and "@@end <n>" markers. Inside the code, print() goes to out.log.
-- Not for shipping: anything that can write this folder can run code in the game.

local poll = 0
local lastId = nil

local function append(text)
    local f = io.open("out.log", "a")
    if f then
        f:write(text, "\n")
        f:close()
    end
end

-- tostring only: GameDump on some values (a TweakDBID, at least) hangs the game under Proton,
-- and pcall can't catch a hang. Call GameDump(x) explicitly in a snippet when it's needed.
local function render(v)
    return tostring(v)
end

local function capture(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[#parts + 1] = render((select(i, ...)))
    end
    append(table.concat(parts, "\t"))
end

-- Commands share the mod's globals (no custom environment: CET's sandbox is picky about
-- load/setfenv); print is swapped for the duration of the command instead.
local function execute(code)
    local fn, err = (loadstring or load)(code)
    if not fn then
        append("compile error: " .. tostring(err))
        return
    end
    local results = { pcall(fn) }
    if not results[1] then
        append("runtime error: " .. tostring(results[2]))
    else
        for i = 2, #results do append("=> " .. render(results[i])) end
    end
end

local function run(id, code)
    append("@@begin " .. id)
    local originalPrint = print
    print = capture
    local ok, err = pcall(execute, code)
    print = originalPrint
    if not ok then append("harness error: " .. tostring(err)) end
    append("@@end " .. id)
end

registerForEvent("onInit", function()
    -- Skip whatever command was left over from a previous session.
    local f = io.open("cmd.lua", "r")
    if f then
        lastId = (f:read("*l") or ""):match("^%-%- id: (%S+)")
        f:close()
    end
    append("@@ready " .. os.date("%Y-%m-%d %H:%M:%S"))
end)

registerForEvent("onUpdate", function(dt)
    poll = poll + dt
    if poll < 0.5 then return end
    poll = 0
    local f = io.open("cmd.lua", "r")
    if not f then return end
    local first = f:read("*l") or ""
    local id = first:match("^%-%- id: (%S+)")
    if not id or id == lastId then
        f:close()
        return
    end
    local code = f:read("*a") or ""
    f:close()
    lastId = id
    run(id, code)
end)
