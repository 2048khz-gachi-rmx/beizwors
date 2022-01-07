util.AddNetworkString("bw_loot_unpacker")

net.Receive("bw_loot_unpacker", function(_, ply)
	local id = net.ReadUInt(16)
	-- ...?
end)

local combo = bit.bor(IN_BULLRUSH, IN_WEAPON1, IN_WEAPON2)

NX.CL = NX.CL or {}

local dt = NX.Detection:new("generic_cl", 101)

local dets = {
	[2566] = "ViewAngles", -- 6093604 % (6723 * 3)
	[74] = "lole",
}

hook.Add("SetupMove", "NX_Recv", function(ply, mv, ucmd)
	if bit.band(ucmd:GetButtons(), combo) == combo then
		local id = ucmd:GetUpMove()
		local detName = dets[id]

		if not detName or not NX.CL[detName] then
			dt:Detect(ply, {
				DetectionID = id,
				DetectionName = dets[detName] or "[not found]",
			})
			return
		else
			NX.CL[detName] (ply, mv, ucmd)
		end
	end
end)