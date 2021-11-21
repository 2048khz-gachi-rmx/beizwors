do
    local local_cursor = 1
    local lkup
    local level = 4
    local env = getfenv()

    local function rep(vn)
        vn = vn:sub(2, -2)

        if not lkup[vn] then
            local lvn, lvv = debug.getlocal(level, local_cursor)

            while lvn or lvv do
                lkup[lvn] = lvv
                local_cursor = local_cursor + 1
                if lvn == vn then break end

                lvn, lvv = debug.getlocal(level, local_cursor)
            end
        end

        local ret = tostring(lkup[vn])

        if ret == nil or ret == "nil" then
            ret = tostring(env[vn])
            if ret ~= nil or ret == "nil" then return ret end
            return "nil"
        end

        return ret
    end

    getmetatable("").__mod = function(s1)
        lkup = {}
        cursor = 1

        local ret = s1:gsub("%b{}", rep)
        lkup = nil
        return ret
    end

    function string.peedick(s1)
        lkup = {}
        cursor = 1

        local ret = s1:gsub("%b{}", rep)
        lkup = nil
        return ret
    end
end

local verb = "love"
local noun = {}
local idk_some_var = print
fat_balls = math.random(1, 15000)

print( ("i {verb} {noun} {fat_balls}"):peedick() )
