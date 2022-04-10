AIBases.Builder = AIBases.Builder or {}
local bld = AIBases.Builder
bld.NW = bld.NW or Networkable("aibuild")

bld.Tracker = bld.Tracker or muldim:new()
bld.EntTracker = bld.EntTracker or muldim:new()

StartTool("AIBaseBuild")

TOOL.Name = "[sadmin] BaseBuild"
TOOL.Category = "AIBases"

function bld.Allowed(ply)
	if not IsValid(ply) or (not BaseWars.IsDev(ply) and not ply.CAN_USE_AIBASE) then return false end

	return true
end

function TOOL:Allowed()
	local p = self:GetOwner()
	if not bld.Allowed(p) then return false end

	return true
end

local function setEnum(ow, e, id)
	assert(IsPlayer(ow))
	assert(isnumber(id) or id == nil)

	local elist = bld.Tracker:GetOrSet(ow)
	elist[e] = id

	local plylist = bld.EntTracker:GetOrSet(e)
	plylist[ow] = true

	bld.NW[ow:UserID()] = bld.NW[ow:UserID()] or {}
	bld.NW[ow:UserID()][e] = id
	bld.NW:SetTable(ow:UserID(), bld.NW[ow:UserID()])
end

AIBases.Builder.AddBrick = setEnum

function TOOL:LeftClick(tr)
	if not IsFirstTimePredicted() then return end

	local e = tr.Entity
	if not IsValid(e) then return end

	local ow = self:GetOwner()
	if not self:Allowed() then return end

	setEnum(ow, e, AIBases.BRICK_PROP)
end

function TOOL:Reload(tr)
	if not IsFirstTimePredicted() then return end

	local e = tr.Entity
	if not IsValid(e) then return end

	local ow = self:GetOwner()
	if not self:Allowed() then return end

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