

local cur = 2459

Positions = Positions or {}
local poses = Positions

hook.Add("PlayerButtonDown", "a", function(p, b)
    if not IsFirstTimePredicted() then return end
    if b == MOUSE_5 then
        poses[cur] = poses[cur] or {}
        poses[cur][#poses[cur] + 1] = {
            me:GetEyeTrace().StartPos,
            me:EyeAngles()
        }
    elseif b == KEY_N then
        PrintTable(poses)
    end
end)

local ind = 0
local function di()
    return ("   "):rep(ind)
end

local function open(i)
    MsgC((not i and di() or "") .. "{\n")
    ind = ind + 1
end

local function close()
    ind = ind - 1
    MsgC(di() .. "},\n")
end

open()
for k,v in pairs(Positions) do
    MsgC(di() .. "[" .. k .. "] = ") open(true)
        for k,v in ipairs(v) do
            open()
                MsgC(di() .. "Vector(" .. table.concat({v[1]:Unpack()}, ", ") .. "),\n")
                MsgC(di() .. "Angle(" .. table.concat({v[2]:Unpack()}, ", ") .. "),\n")
            close()
        end
    close()
end
close()