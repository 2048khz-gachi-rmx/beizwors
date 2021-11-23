local BWAddons = {
    "160250458", --wire
    "922947756", --synths

    game.GetMap() == "rp_downtown_tits_v2" and "1590239460" or -- tits
    game.GetMap():match("evocity") and "296828130", --bw evocity

    -- "506283460", --csgo kneivs
    "546392647", --media players
    -- "284266415",
    -- "2447979470", -- stormcocks 2

    "1796166180", -- particles content
    "1804934154", -- particles - hit

    "2131057232", -- arccw base(d on what)
    -- 2179387416, -- arccw arknights charms because aerach
    "2131058270", -- arccw cs+
    --"2135529088", -- arccw mw2
    "2175261690", -- arccw fa:s 1
    "2131161276", -- arccw m9k "extras"
    "2257255110", -- arccw GO
    "2393318131", -- arccw fa:s 2
    --"2306829669", -- arccw home defense
    "2427171109", -- gso unlamifier

    "2409364730", -- gunsmith offensive extras

    "2155366756", -- vmanip

    -- cw2
    "427204862", -- raging bull
    "838920776", -- bullpups
    "591075724", -- mosin
    "1589205037", -- acr
    "349050451", -- cw2 base
    "657241323", -- ins2
    "358608166", -- cw2 unofficial
}

local preMcore = GetConVar("gmod_mcore_test"):GetInt()
local preQueue = GetConVar("mat_queue_mode"):GetInt()
local mountQueue = {}

local function startTimer()
    if timer.Exists("mount_delay") then return end

    RunConsoleCommand("gmod_mcore_test", "0")
    RunConsoleCommand("mat_queue_mode", "0")

    timer.Create("mount_delay", 1, 1, function()
        hook.Once("PreRender", "lole", function()
            for k,v in ipairs(mountQueue) do
                game.MountGMA(v)
            end

            timer.Simple(0, function()
                RunConsoleCommand("gmod_mcore_test", tostring(pre))
                RunConsoleCommand("mat_queue_mode", tostring(preQueue))
            end)
        end)
    end)
end

concommand.Add("try_dl_ws", function()
    for k,v in ipairs(BWAddons) do
        steamworks.DownloadUGC(v, function(path, fobj)
            mountQueue[#mountQueue + 1] = path
            startTimer()
        end)
    end
end)