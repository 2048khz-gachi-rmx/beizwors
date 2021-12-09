local bw = BaseWars
bw.Statuses = {}
local bs = bw.Statuses
bs.Statuses = bs.Statuses or {}

bs.BaseStatus = Emitter:extend()

bs.IDConv = bs.IDConv or {ToName = {--[[ id = name ]]}, ToID = {--[[ name = id ]]}}

function bs.EncodeStatuses()
	for k,v in pairs(bs.Statuses) do
		if bs.IDConv.ToID[k] then continue end
		local id = v:GetID()

		bs.IDConv.ToName[id] = k
		bs.IDConv.ToID[k] = id
	end
end

local bstat = bs.BaseStatus

ChainAccessor(bstat, "Name", "Name")
ChainAccessor(bstat, "ID", "ID")

bstat.IsBaseStatus = true

function IsBaseStatus(what)
	return istable(what) and what.IsBaseStatus
end

function bstat:SetName(name)
	if self:GetName() then
		bs.Statuses[self:GetName()] = nil
	end

	bs.Statuses[name] = self
	self.Name = name
	return self
end

function bstat:Initialize(name, id)
	if not name then error("basestatus requires name bro") return end
	if not id then error("basestatus requires id bro") return end

	self:SetName(name)
	self:SetID(id)
end

function bstat:Hook(ev, fn)
	if not hooks:Get(ev) then
		hook.Add(ev, "BW_Statuses", function(...) bs.HookRun(ev, ...) end)
	end

	hooks:Set(fn, ev, self:GetName())

	return self
end

--[==================================[
				utility
--]==================================]

function bstat.IDToName(id)
	return (isstring(id) and bstat.IDConv.ToID[id] and id) or bstat.IDConv.ToName[id]
end

function bstat.NameToID(name)
	return (isnumber(name) and bstat.IDConv.ToName[name] and name) or bstat.IDConv.ToID[name]
end

bstat.ToID = bstat.NameToID
bstat.ToName = bstat.IDToName

function bstat.Get(what)
	if IsBaseStatus(what) then return what end

	local nm = bstat.IDToName(what) or (isstring(what) and what)
	return bs.Statuses[nm]
end
