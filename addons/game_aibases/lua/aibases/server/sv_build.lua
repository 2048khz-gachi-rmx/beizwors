local ENTITY = FindMetaTable("Entity")

AIBases.Builder = AIBases.Builder or {}
local bld = AIBases.Builder
bld.NW = Networkable("aibuild")

bld.Tracker = bld.Tracker or muldim:new()
bld.EntTracker = bld.EntTracker or muldim:new()

StartTool("AIBaseBuild")

TOOL.Name = "[sadmin] BaseBuild"

local function allowed(ply)
	if not IsValid(ply) or (not BaseWars.IsDev(ply) and not ply.CAN_USE_AIBASE) then return false end

	return true
end

function TOOL:Allowed()
	local p = self:GetOwner()
	if not allowed(p) then return false end

	return true
end

local function setEnum(ow, e, id)
	bld.NW[ow:UserID()] = bld.NW[ow:UserID()] or {}
	bld.NW[ow:UserID()][e] = id
	bld.NW:SetTable(ow:UserID(), bld.NW[ow:UserID()])
end

function TOOL:LeftClick(tr)
	if not IsFirstTimePredicted() then return end

	local e = tr.Entity
	if not IsValid(e) then return end

	local ow = self:GetOwner()
	if not self:Allowed() then return end

	local elist = bld.Tracker:GetOrSet(ow)
	elist[e] = AIBases.BRICK_PROP

	local plylist = bld.EntTracker:GetOrSet(e)
	plylist[ow] = true

	setEnum(ow, e, AIBases.BRICK_PROP)
end

function TOOL:Reload(tr)
	if not IsFirstTimePredicted() then return end

	local e = tr.Entity
	if not IsValid(e) then return end

	local ow = self:GetOwner()
	if not self:Allowed() then return end

	local elist = bld.Tracker:GetOrSet(ow)
	elist[e] = AIBases.BRICK_BOX

	local plylist = bld.EntTracker:GetOrSet(e)
	plylist[ow] = true

	setEnum(ow, e, AIBases.BRICK_BOX)
end

function TOOL:RightClick(tr)
	if not IsFirstTimePredicted() then return end

	local e = tr.Entity
	if not IsValid(e) then return end

	local ow = self:GetOwner()

	local elist = bld.Tracker:GetOrSet(ow)
	elist[e] = nil

	local plylist = bld.EntTracker:GetOrSet(e)
	plylist[ow] = nil

	bld.NW[ow:UserID()] = bld.NW[ow:UserID()] or {}
	bld.NW[ow:UserID()][e] = nil
	bld.NW:SetTable(ow:UserID(), bld.NW[ow:UserID()])
end

function TOOL:GetList()
	return bld.Tracker:GetOrSet(self:GetOwner())
end

EndTool()

function ENTITY:GetAIBuilders()
	return bld.EntTracker:GetOrSet(self)
end


concommand.Add("aibases_save", function(ply, _, arg)
	if not allowed(ply) then return end

	local basename = arg[1]
	if not arg[1] then print("give a name tard") return end
	print("saving base `" .. basename .. "`...")

	local tool = GetTool("AIBaseBuild", ply)
	if not tool then print("no tool") return end

	local bents = tool:GetList()
	PrintTable(bents)

	for ent, id in pairs(bents) do
		local base = AIBases.IDToLayout(id)
		local brick = base:Build(ent)
		print("	base:", base, ent, brick)
	end
end)