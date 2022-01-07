net.Receive("AnalProbing", function(len, ply)
	if not ply.Probing then print("Player attempted to return probe without actually being probed") return end

	local acl = net.ReadString()
	local src = net.ReadString()
	print(ply, "\nsv_allowcslua:", acl,"\ndebug.getinfo render.Capture:", src)

end)
--------

--[[
	PAC Fix
	Restrict PAC to VIP's, this time properly
]]

hook.Add("PrePACConfigApply", "PACDust", function(ply)
	if not table.HasValue(BaseWars.Config.VIPRanks,ply:GetUserGroup()) and not ply:IsAdmin() and not ply:IsSuperAdmin() then
		return false, "Not enough privileges!"
	end
end)

hook.Add("CanWearParts", "PACStop", function(ply)
	if not table.HasValue(BaseWars.Config.VIPRanks,ply:GetUserGroup()) and not ply:IsAdmin() and not ply:IsSuperAdmin() then
		return false,"Not enough privileges!"
	end
end)

--[[
	Adv. Dupe 2 Fix
	Log trash when people use "inf" or beyond reasonable ModelScale on dupes.
]]

local function AntiDupeTrash()

	net.Receivers["armdupe"] = function(len,ply)
		if ply:IsAdmin() or ply:IsSuperAdmin() then return  --you don't need it anyways

		else
			print(tostring(ply).. " tried to arm a dupe despite lacking admin privileges.")
		end

	end

end

hook.Add("InitPostEntity", "AntiDupeCrash",function()
	AntiDupeTrash()
end)


local bad = {
	"models/cranes/crane_frame.mdl",
	"models/items/item_item_crate.mdl",
	"models/props/cs_militia/silo_01.mdl",
	"models/props/cs_office/microwave.mdl",
	"models/props/de_train/biohazardtank.mdl",
	"models/props_buildings/building_002a.mdl",
	"models/props_buildings/collapsedbuilding01a.mdl",
	"models/props_buildings/project_building01.mdl",
	"models/props_buildings/row_church_fullscale.mdl",
	"models/props_c17/consolebox01a.mdl",
	"models/props_c17/oildrum001_explosive.mdl",
	"models/props_c17/paper01.mdl",
	"models/props_c17/trappropeller_engine.mdl",
	"models/props_canal/canal_bridge01.mdl",
	"models/props_canal/canal_bridge02.mdl",
	"models/props_canal/canal_bridge03a.mdl",
	"models/props_canal/canal_bridge03b.mdl",
	"models/props_combine/combine_citadel001.mdl",
	"models/props_combine/combine_mine01.mdl",
	"models/props_combine/combinetrain01.mdl",
	"models/props_combine/combinetrain02a.mdl",
	"models/props_combine/combinetrain02b.mdl",
	"models/props_combine/prison01.mdl",
	"models/props_combine/prison01c.mdl",
	"models/props_industrial/bridge.mdl",
	"models/props_junk/garbage_takeoutcarton001a.mdl",
	"models/props_junk/gascan001a.mdl",
	"models/props_junk/glassjug01.mdl",
	"models/props_junk/trashdumpster02.mdl",
	"models/props_phx/amraam.mdl",
	"models/props_phx/ball.mdl",
	"models/props_phx/cannonball.mdl",
	"models/props_phx/huge/evildisc_corp.mdl",
	"models/props_phx/misc/flakshell_big.mdl",
	"models/props_phx/misc/potato_launcher_explosive.mdl",
	"models/props_phx/mk-82.mdl",
	"models/props_phx/oildrum001_explosive.mdl",
	"models/props_phx/torpedo.mdl",
	"models/props_phx/ww2bomb.mdl",
	"models/props_wasteland/cargo_container01.mdl",
	"models/props_wasteland/cargo_container01.mdl",
	"models/props_wasteland/cargo_container01b.mdl",
	"models/props_wasteland/cargo_container01c.mdl",
	"models/props_wasteland/depot.mdl",
	"models/xqm/coastertrack/special_full_corkscrew_left_4.mdl",
}