
local bw = BaseWars.Bases
local nw = bw.NW

local function createNewBase(ply, pr)
	local ns = netstack:new()

	local name = net.ReadString()

	local a, err = bw.SQL.CreateBase(name)

	if err then
		ns:WriteCompressedString(err)
		pr:ReplySend("BWBases", false, ns)
		return
	end

	a:Then(function(_, q)
		ns:WriteUInt(q:lastInsert(), nw.SZ.base)
		pr:ReplySend("BWBases", true, ns)
	end, function(_, why)
		ns:WriteCompressedString("query failed:\n" .. why)
		pr:ReplySend("BWBases", false, ns)
	end)
end

local function createNewZone(ply, pr)
	local ns = netstack:new()

	local baseID = net.ReadUInt(nw.SZ.base)
	local name = net.ReadString()
	local mins, maxs = net.ReadVector(), net.ReadVector()

	local a, err = bw.SQL.CreateZone(name, baseID, mins, maxs)

	if err then
		ns:WriteCompressedString(err)
		pr:ReplySend("BWBases", false, ns)
		return
	end

	a:Then(function(_, q)
		ns:WriteUInt(q:lastInsert(), nw.SZ.zone)
		pr:ReplySend("BWBases", true, ns)
	end, function(_, why)
		ns:WriteCompressedString("query failed:\n" .. why)
		pr:ReplySend("BWBases", false, ns)
	end)
end

local function editZone(ply, pr)
	local ns = netstack:new()

	local zoneID = net.ReadUInt(nw.SZ.zone)
	local name = net.ReadString()
	local mins, maxs = net.ReadVector(), net.ReadVector()

	local zone = bw.GetZone(zoneID)
	if not zone then
		ns:WriteCompressedString("didn't find zone with ID " .. zoneID)
		pr:ReplySend("BWBases", false, ns)
		return
	end

	local a, err = bw.SQL.EditZone(zoneID, name, mins, maxs)

	if err then
		ns:WriteCompressedString(err)
		pr:ReplySend("BWBases", false, ns)
		return
	end

	a:Then(function(_, q)
		pr:ReplySend("BWBases", true, ns)
		zone:SetBounds(mins, maxs)
		zone:SetName(name)
	end, function(_, why)
		ns:WriteCompressedString("query failed:\n" .. why)
		pr:ReplySend("BWBases", false, ns)
	end)
end

local function editBase(ply, pr)
	local ns = netstack:new()

	local baseID = net.ReadUInt(nw.SZ.base)
	local name = net.ReadString()

	local base = bw.GetBase(baseID)
	if not base then
		ns:WriteCompressedString("didn't find base with ID " .. zoneID)
		pr:ReplySend("BWBases", false, ns)
		return
	end

	local a, err = bw.SQL.EditBase(baseID, name)

	if err then
		ns:WriteCompressedString(err)
		pr:ReplySend("BWBases", false, ns)
		return
	end

	a:Then(function(_, q)
		pr:ReplySend("BWBases", true, ns)
		base:SetName(name)
		base:AddToNW()
	end, function(_, why)
		ns:WriteCompressedString("query failed:\n" .. why)
		pr:ReplySend("BWBases", false, ns)
	end)
end

local function yeetBase(ply, pr)
	local ns = netstack:new()

	local ID = net.ReadUInt(nw.SZ.base)
	local base = bw.GetBase(ID)

	if not base then
		ns:WriteCompressedString("didn't find base with ID " .. ID)
		pr:ReplySend("BWBases", false, ns)
		return
	end

	local a, err = bw.SQL.YeetBase(ID)

	if err then
		ns:WriteCompressedString(err)
		pr:ReplySend("BWBases", false, ns)
		return
	end

	a:Then(function(_, q)
		pr:ReplySend("BWBases", true, ns)
	end, function(_, why)
		ns:WriteCompressedString("query failed:\n" .. why)
		pr:ReplySend("BWBases", false, ns)
	end)
end

local function yeetZone(ply, pr)
	local ns = netstack:new()

	local ID = net.ReadUInt(nw.SZ.zone)
	local zone = bw.GetZone(ID)

	if not zone then
		ns:WriteCompressedString("didn't find zone with ID " .. ID)
		pr:ReplySend("BWBases", false, ns)
		return
	end

	local a, err = bw.SQL.YeetZone(ID)

	if err then
		ns:WriteCompressedString(err)
		pr:ReplySend("BWBases", false, ns)
		return
	end

	a:Then(function(_, q)
		pr:ReplySend("BWBases", true, ns)
	end, function(_, why)
		ns:WriteCompressedString("query failed:\n" .. why)
		pr:ReplySend("BWBases", false, ns)
	end)
end

local function spawnCore(ply, pr)
	local ns = netstack:new()

	local ID = net.ReadUInt(nw.SZ.base)
	local base = bw.GetBase(ID)

	if not base then
		ns:WriteCompressedString("didn't find base with ID " .. ID)
		pr:ReplySend("BWBases", false, ns)
		return
	end

	-- jesus
	local baseCore = scripted_ents.GetStored("bw_basecore")
	if not baseCore or not baseCore.t or not baseCore.t.Model then
		ns:WriteCompressedString("didn't find basecore entity/model somehow...?")
		pr:ReplySend("BWBases", false, ns)
		return
	end

	local ok, ent = pcall(DoPlayerEntitySpawn, ply, "prop_physics", baseCore.t.Model, 0)

	if not ok then
		ns:WriteCompressedString("error while spawning: " .. ent)
		pr:ReplySend("BWBases", false, ns)
		return
	elseif not ent:IsValid() then
		ns:WriteCompressedString("spawned prop wasn't valid, somehow...")
		pr:ReplySend("BWBases", false, ns)
		return
	end

	ns:WriteUInt(ent:EntIndex(), 16)
	pr:ReplySend("BWBases", true, ns)
end

local function saveCore(ply, pr)
	local ns = netstack:new()
	local ID = net.ReadUInt(nw.SZ.base)
	local base = bw.GetBase(ID)

	if not base then
		ns:WriteCompressedString("didn't find base with ID " .. ID)
		pr:ReplySend("BWBases", false, ns)
		return
	end

	local eid = net.ReadUInt(16)
	local ent = Entity(eid)
	if not IsValid(ent) then
		ns:WriteCompressedString("didn't find entity with EntIndex " .. eid)
		pr:ReplySend("BWBases", false, ns)
		return
	end

	base:GetData().BaseCore = {
		pos = ent:GetPos(),
		ang = ent:GetAngles(),
		mdl = ent:GetModel()
	}

	local json = util.TableToJSON(base:GetData())
	local a, err = bw.SQL.SaveData(ID, json)

	if err then
		ns:WriteCompressedString(err)
		pr:ReplySend("BWBases", false, ns)
		return
	end

	a:Then(function(_, q)
		pr:ReplySend("BWBases", true, ns)
		ent:Remove()
		base:SpawnCore()
	end, function(_, why)
		ns:WriteCompressedString("query failed:\n" .. why)
		pr:ReplySend("BWBases", false, ns)
	end)
end

local function editData(ply, pr)
	local ID = net.ReadUInt(nw.SZ.base)
	local base = bw.GetBase(ID)

	if not base then
		ns:WriteCompressedString("didn't find base with ID " .. ID)
		pr:ReplySend("BWBases", false, ns)
		return
	end

	--[[local key = net.ReadString()
	local val = net.ReadString()

	base:GetData()[key] = val
	base:SaveData()

	pr:ReplySend("BWBases", true, ns)]]
end

local function DetermineAction(mode, ply, pr)
	local ns = netstack:new()

	if not bw.CanModify(ply) then
		ns:WriteCompressedString("no permissions")
		pr:ReplySend("BWBases", false, ns)
		return
	end

	if mode == bw.NW.BASE_NEW then
		createNewBase(ply, pr)
	elseif mode == bw.NW.BASE_EDIT then
		editBase(ply, pr)
	elseif mode == bw.NW.ZONE_EDIT then
		editZone(ply, pr)
	elseif mode == bw.NW.ZONE_NEW then
		createNewZone(ply, pr)
	elseif mode == bw.NW.ZONE_YEET then
		yeetZone(ply, pr)
	elseif mode == bw.NW.BASE_YEET then
		yeetBase(ply, pr)
	elseif mode == bw.NW.BASE_CORENEW then
		spawnCore(ply, pr)
	elseif mode == bw.NW.BASE_CORESAVE then
		saveCore(ply, pr)
	elseif mode == bw.NW.BASE_BASEDATA then
		editData(ply, pr)
	else
		local ns = netstack:new()
		ns:WriteCompressedString("Unhandled action.")
		pr:ReplySend("BWBases", false, ns)
	end

end

net.Receive("BWBases", function(l, ply)
	local mode = net.ReadUInt(4)
	local pr = net.ReplyPromise(ply)

	local ok, err = pcall(DetermineAction, mode, ply, pr)
	if not ok then
		ns:WriteCompressedString("Error!")
		pr:ReplySend("BWBases", false, ns)
		return false
	end
end)