--soon:tm:
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/grp/computers/supercomputer_01.mdl"

util.AddNetworkString("ResearchComputer")


function ENT:Init()
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	self:DrawShadow(false)
	self:SetModelScale(1)

	self.LastPwThink = CurTime()
	self.TimeResearching = 0
	self.NeedTime = 0
end

function ENT:Use(ply, a, b, c)
	if ply ~= a or not IsPlayer(ply) then return end

	net.Start("ResearchComputer")
		net.WriteBool(false) -- not a promise response
		net.WriteEntity(self)
	net.Send(ply)
end

function ENT:FinishResearch()
	local ow = self:BW_GetOwner()
	if not ow then
		errorf("NO OWNER TO FINISH RESEARCH!?!?!? %s %s %s", ow,
			self, self.CPPI_OwnerSID)
		return
	end

	local perk = Research.GetPerk(self:GetRSPerk())
	if not perk then
		errorf("NO PERK!?", self:GetRSPerk())
		return
	end

	local lv = perk:GetLevel(self:GetRSLevel())
	if not lv then
		errorf("NO LEVEL!?", lv)
		return
	end

	Research.ResearchLevel(ow, lv)

	self:SetRSPerk("")
	self:SetRSLevel(0)
	self:SetRSProgress(0)
end

function ENT:RequestFinish(ply)
	local have = math.min(1, self.TimeResearching / self.NeedTime)
	if have ~= 1 then return false end

	self:FinishResearch()
	return true
end

function ENT:Think()
	if self:GetRSLevel() == 0 then
		self:NextThink(CurTime() + 1)
		self.LastPwThink = CurTime()
		return true
	end

	local last = self.LastPwThink
	local passed = CurTime() - last
	local hasnext = false

	self.LastPwThink = CurTime()

	if self:IsPowered() then
		self.TimeResearching = self.TimeResearching + passed

		if self.Unpowered then
			self.Unpowered = nil

			self:SetRSTime(last)
			self:SetRSHalted(false)
		end
	else
		self:SetRSTime(self.TimeResearching)

		local have = math.min(1, self.TimeResearching / self.NeedTime)
		self:SetRSProgress(have)

		self.Unpowered = true
		self:SetRSHalted(true)

		self:NextThink(CurTime() + 0.5)
		hasnext = true
	end

	--[[printf("%s thinks we're %.1f%% there (%.1f -> %.1f)", Realm(),
		self.TimeResearching / self.NeedTime * 100,
		self.TimeResearching, self.NeedTime)]]

	if hasnext then return true end
end

function ENT:RequestResearch(ply)
	local perkID = net.ReadString()
	local lvNum = net.ReadUInt(16)
	local perk = Research.GetPerk(perkID)

	if not perk then
		return false
	end

	local level = perk:GetLevel(lvNum)
	if not level then
		return false
	end

	if self:GetRSLevel() ~= 0 then
		return false
	end

	local preqs = level:GetPrereqs()
	local reqs = level:GetRequirements()

	--[=======================[
		check computer level
	--]=======================]

	if reqs.Computer then
		if reqs.Computer < self:GetLevel() then
			print("missing computer level", reqs.Computer)
			return false
		end
	end

	--[==============================[
		check prerequisite research
	--]==============================]

	for id, lv in pairs(preqs) do
		local has = ply:HasPerkLevel(id, lv)
		if not has then
			print("player missing prerequisite:", id, lv)
			return false
		end
	end

	--[==============[
		check items
	--]==============]

	local inv = Inventory.GetTemporaryInventory(ply)

	for id, amt in pairs(reqs.Items) do
		local cnt = Inventory.Util.GetItemCount(inv, id)
		if cnt < amt then
			print("player missing item")
			return false
		end
	end

	--[=========================[
		all good; start research
	--]=========================]

	print("dont forget to take the inventory items too")
	self:SetRSPerk(perk:GetID())
	self:SetRSLevel(level:GetLevel())
	self:SetRSTime(CurTime())
	self:SetRSProgress(0)
	self:SetRSHalted(not self:IsPowered())

	self.TimeResearching = 0
	self.NeedTime = level:GetResearchTime()

	return true
end

local function reply(pr, b)
	net.Start("ResearchComputer")
		net.WriteBool(true)
		pr:Reply(b)
	net.Send(pr.Owner)
end

local methods = {
	[0] = ENT.RequestResearch,
	[1] = ENT.RequestFinish,
	[2] = nil,
}

net.Receive("ResearchComputer", function(_, ply)
	local pr = net.ReplyPromise(ply)

	local method = net.ReadUInt(4)
	local comp = net.ReadEntity()

	if not IsValid(comp) or not comp.ResearchComputer
		or not comp:BW_IsOwner(ply) then
		reply(pr, false)
		return false
	end

	if not methods[method] then
		reply(pr, false)
		return false
	end

	local ok = methods[method] (comp, ply)
	reply(pr, ok)

	if not ok then return ok end
end)