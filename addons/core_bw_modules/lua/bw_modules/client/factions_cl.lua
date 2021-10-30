local tag = "BaseWars.Factions"
MODULE.Name = "FactionsCL"

local facmeta = Factions.meta
Factions.Factions = Factions.Factions or {}
Factions.FactionIDs = Factions.FactionIDs or {}

local Promises = {}

local function promise()
	local retProm = Promise() -- promise to return
	local funcProm = Promise() -- functional prom

	funcProm:Then(function()
		local ok = net.ReadBool()
		local whyNot = not ok and net.ReadLocalString(Factions.Errors)

		if not ok then
			retProm:Reject(whyNot)
		else
			retProm:Resolve(ok)
		end
	end)

	local uid = uniq.Seq("Faction promises", 8)

	Promises[uid] = funcProm

	return retProm, uid
end

function facmeta:Initialize(id, name, col, haspw)

	--if id > 0 or CLIENT then
		self.PublicNW = LibItUp.Networkable:new("Faction:" .. id)
			self.PublicNW:Alias("Leader", 2)
			self.PublicNW:Alias("PlayerInfo", 3)
		self:_HookNW(self.PublicNW)
	--end

	self.id = id
	self.name = name
	self.col = col
	self.haspw = haspw
	self._Valid = true

	return new
end

function facmeta:Remove()
	for k, pinfo in ipairs(self:GetMembersInfo()) do
		hook.NHRun("PlayerLeftFaction", self, pinfo:GetPlayer(), pinfo)
	end

	Factions.FactionIDs[self.id] = nil
	Factions.Factions[self.name] = nil
	self._Valid = false
	self.PublicNW:Invalidate()

	hook.NHRun("FactionDisbanded", self)
end

function facmeta:IsValid()
	return self._Valid ~= false
end

function facmeta:InRaid()
	return self.PublicNW:Get("Raided") or self.PublicNW:Get("Raider")
end

function facmeta:GetMembers()
	local ret = {}

	for k,v in ipairs(self:GetMembersInfo()) do
		if v:GetPlayer() then
			ret[#ret + 1] = v:GetPlayer()
		end
	end

	return ret
end

function facmeta:GetMembersInfo()
	return self.PublicNW:Get("PlayerInfo") or {}
end

function facmeta:IsMember(what)
	local pinfo = GetPlayerInfoGuarantee(what)
	return table.HasValue(self:GetMembersInfo(), pinfo) and pinfo
end

function facmeta:GetLeader()
	local ld = self.PublicNW:Get("Leader")
	if ld and ld:GetPlayer() and ld:GetPlayer():IsValid() then
		return ld:GetPlayer()
	end

	return false
end

facmeta.GetOwner = facmeta.GetLeader

function facmeta:GetLeaderInfo()
	return self.PublicNW:Get("Leader")
end

facmeta.GetOwnerInfo = facmeta.GetLeaderInfo

function facmeta:GetName()
	return self.name
end

function facmeta:GetColor()
	return self.col
end

function facmeta:HasPassword()
	return self.haspw or false
end

function facmeta:GetID()
	return self.id
end

function facmeta:_HookNW(nw)
	nw:On("NetworkedVarChanged", "TrackMembers", function(_, key, old, new)
		if key == "Leader" then
			hook.NHRun("FactionChangedLeader", self, old, new)
			return
		end
	end)

	-- instead of running the hooks straight away, store them here
	-- and run them after finishing reading the changes
	local postHookRuns = {}

	nw:On("NetworkedChanged", function()
		hook.NHRun("FactionsUpdate", self)
		for k,v in ipairs(postHookRuns) do
			v()
		end

		table.Empty(postHookRuns)
	end)

	nw:On("ReadChangeValue", "ReadPlayerInfo", function(nw, key)
		if key ~= "PlayerInfo" and key ~= "Leader" then return end

		if key == "Leader" then
			return GetPlayerInfoGuarantee(net.ReadString(), true)
		end

		local prev_membs = self:GetMembersInfo()

		local arr = {}
		local list = {}

		local count = net.ReadUInt(4)

		for i=1, count do
			local sid64 = net.ReadString()

			arr[i] = GetPlayerInfoGuarantee(sid64, true)
			arr[i]._Faction = self

			list[sid64] = arr[i]
		end

		for k, pinfo in ipairs(prev_membs) do
			local sid =  pinfo:GetSteamID64()
			if not list[sid] then
				table.insert(postHookRuns, function()
					hook.NHRun("PlayerLeftFaction", self, pinfo:GetPlayer(), pinfo)
					self:Emit("LeftPlayer", pinfo:GetPlayer(), pinfo)
				end)
			end

			list[sid] = nil
		end

		for sid, pinfo in pairs(list) do
			table.insert(postHookRuns, function()
				hook.NHRun("PlayerJoinedFaction", self, pinfo:GetPlayer(), pinfo)
				self:Emit("JoinedPlayer", pinfo:GetPlayer(), pinfo)
			end)
		end

		return arr
	end)
end

local PLAYER = debug.getregistry().Player

net.Receive("Factions", function(len)

	local type = net.ReadUInt(4)

	printf('CL: Factions: Type %s; size: %s bytes', type, len/8)

	if type == 1 then -- full update

		Factions.Factions = {}

		local amt = net.ReadUInt(16)

		for i=1, amt do
			local id = net.ReadUInt(24)
			local name = net.ReadString()
			local col = net.ReadColor()

			local haspw = net.ReadBool()

			team.SetUp(id, name, col, false)

			local fac = Factions.FactionIDs[id] or facmeta:new(id, name, col, haspw)
			Factions.Factions[name] = fac
			Factions.FactionIDs[id] = fac

			--[[Factions.Factions[name] = {id = id, name = name, col = col, own = lead, pw = haspw}
			Factions.FactionIDs[id] = {id = id, name = name, col = col, own = lead, pw = haspw}]]
		end

	elseif type == 2 then -- update

		local id = net.ReadUInt(24)
		local name = net.ReadString()
		local col = net.ReadColor()

		local haspw = net.ReadBool()

		team.SetUp(id, name, col, false)

		print("created new faction:", id, name)

		local fac = Factions.FactionIDs[id] or facmeta:new(id, name, col, haspw)
		Factions.Factions[name] = fac
		Factions.FactionIDs[id] = fac

	elseif type == 3 then

		local id = net.ReadUInt(24)

		for k,v in pairs(Factions.Factions) do
			if v.id and v.id==id then
				v:Remove()
				Factions.Factions[k] = nil
				Factions.FactionIDs[id] = nil
				break
			end
		end

	end

	if type==10 then
		print("Received resolver net")
		local echo_uid = net.ReadUInt(8)
		print("Resolving id", echo_uid, Promises[echo_uid])
		if Promises[echo_uid] then
			print("ayup existed")
			Promises[echo_uid]:Exec()
			Promises[echo_uid] = nil
		end

		return
	end
	hook.NHRun("FactionsUpdate")
end)

function GetFactions()
	return Factions.Factions
end

function PLAYER:InFaction(ply2)
	local fac = Factions.FactionIDs[self:Team()]

	if not ply2 then
		if fac then return fac.name else return false end
	elseif IsPlayer(ply2) then
		local fac2 = Factions.FactionIDs[ply2:Team()]
		if self:Team()~=1 and fac==fac2 then
			return fac.name
		else
			return false
		end
	elseif isnumber(ply2) then
		return self:Team() == ply2
	end
	return false --???
end

function Factions.RequestCreate(name, pw, col)
	if not Factions.CanCreate(name, pw, col, LocalPlayer()) then return false end

	local prom, uid = promise()

	net.Start("Factions")
		net.WriteUInt(Factions.CREATE, 4)
		net.WriteUInt(uid, 8)
		net.WriteString(name)
		net.WriteString(pw)
		net.WriteColor(col)
	net.SendToServer()

	return prom
end

function Factions.RequestKick(whomst)

	net.Start("Factions")
		net.WriteUInt(Factions.KICK, 4)
		net.WriteEntity(whomst)
	net.SendToServer()

end

function Factions.RequestLeave()
	local prom, uid = promise()

	net.Start("Factions")
		net.WriteUInt(Factions.LEAVE, 4)
		net.WriteUInt(uid, 8)
	net.SendToServer()

	return prom
end

function Factions.RequestJoin(fac, pw)
	local prom, uid = promise()

	net.Start("Factions")
		net.WriteUInt(Factions.JOIN, 4)
		net.WriteUInt(uid, 8)
		net.WriteUInt(fac:GetID(), 24)
		net.WriteBool(pw and true or false)
		if pw then net.WriteString(pw) end
	net.SendToServer()

	return prom
end


function Factions.GetSortedFactions()
	local facs = Factions.Factions
	local sorted = {}

	for name, dat in pairs(facs) do
		if dat:GetID() == -1 then continue end
		sorted[#sorted + 1] = {name, dat}
	end

	-- the fucking members can be invalid, wtf????
	pcall(table.sort, sorted, function(a, b)

		local name1, name2 = a[1], a[2]
		local a, b = a[2], b[2] --we're looking at facs

		local memb1 = a:GetMembers()
		local memb2 = b:GetMembers()

		local a_has_friends = false
		local b_has_friends = false

		local a_has_more = #memb1 > #memb2
		local b_has_more = not a_has_more

		local me = LocalPlayer()

		for k,v in ipairs(memb1) do
			if v == me then return true end --auto-move to the top

			if v:GetFriendStatus() == "friend" then
				a_has_friends = true
				break
			end
		end

		for k,v in ipairs(memb2) do
			if v == me then return false end --vi lost

			if v:GetFriendStatus() == "friend" then
				b_has_friends = true
				break
			end
		end

		if a_has_friends and not b_has_friends then return true end 	-- first sort by friends

		if not a_has_more and not b_has_more then return name1 < name2 end -- if member counts are equal, sort alphabetically as a backup plan
		return a_has_more												-- sort by member counts
	end)


	return sorted
end