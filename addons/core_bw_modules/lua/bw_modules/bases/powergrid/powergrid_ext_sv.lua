local bw = BaseWars.Bases
local pg = bw.PowerGrid

--[==================================[
	ownership checks
--]==================================]

local unowned = bw.GridUnowned or {}
bw.GridUnowned = unowned

hook.Add("EntityOwnershipChanged", "PGTrackOwned", function(ply, ent)
	if unowned[ent] then
		local pg = unowned[ent]
		pg:RecheckOwnership(ent)
	end
end)

hook.Add("EntityActuallyRemoved", "PG_Unown", function(ent)
	if unowned[ent] then
		local pg = unowned[ent]
		pg:RecheckOwnership(ent)
	end
end)

pg:On("Initialize", "ServerTracker", function(self, base)
	self._UnpoweredEnts = {}
	self._PoweredEnts = {}
	self._UnownedEnts = {} -- ents that aren't owned by the base's owner

	base:On("Claim", "OwnerCheck", function()
		self:RecheckOwnership()
	end)

	base:On("Unclaim", "OwnerCheck", function()
		self:RecheckOwnership()
	end)
end)

function pg:_unown(ent)
	self._UnownedEnts[ent] = true
	unowned[ent] = self
end

function pg:_yeet(ent)
	self._UnownedEnts[ent] = nil
	unowned[ent] = nil
end

function pg:_own(ent)
	self._UnownedEnts[ent] = nil
	unowned[ent] = nil
end

function pg:_checkOwnershipEnt(ent, base)
	if ent:IsRemoving() then
		self:_yeet(ent)
		return
	end

	if base:IsEntityOwned(ent) then
		self:_own(ent)
		return true
	else
		self:_unown(ent)
		return false
	end
end

function pg:RecheckOwnership(specific_ent)
	local base = self:GetBase()
	if not base or not base:IsValid() then print("not base or not valid") return end

	if specific_ent then
		if self:_checkOwnershipEnt(specific_ent, base) then
			self:AddEntity(specific_ent)
		else
			self:RemoveEntity(specific_ent)
		end
	else
		-- unowned entities aren't part of "all" entities
		-- (they're not consumers nor gens nor batteries)

		-- insert after looping both cuz its possible we'll be double-checking the same ent
		-- it's not gonna break if we double-check, but i'd rather avoid it

		local add, rem = {}, {}
		for ent, _ in pairs(self._UnownedEnts) do
			table.insert(self:_checkOwnershipEnt(ent, base) and add or rem, ent)
		end

		for ent, _ in pairs(self._AllEntities) do
			table.insert(self:_checkOwnershipEnt(ent, base) and add or rem, ent)
		end

		for k,v in ipairs(rem) do
			self:RemoveEntity(v)
		end

		for k,v in ipairs(add) do
			self:AddEntity(v)
		end
	end
end

function pg:DoOwnerCheck(ent)
	local base = self:GetBase()
	local ow = ent:BW_GetOwner()

	-- actually owned by non-world & owned not by the base owner
	if IsValid(ow) and not base:IsEntityOwned(ent) then
		self:_unown(ent)
		return false
	end
end

pg:On("CanAddEntity", "OwnerCheck", function(self, ent)
	return self:DoOwnerCheck(ent)
end)

--[==================================[
	power i/o tracking and ent powering
--]==================================]


function pg:UpdatePowerIn(gen)
	local pw_in = 0
	for k,v in ipairs(self:GetGenerators()) do
		pw_in = pw_in + (v.PowerGenerated or 0)
	end

	self:SetPowerIn(pw_in)
end

pg:On("AddedGenerator", "UpdatePowerIn", pg.UpdatePowerIn)
pg:On("RemovedGenerator", "UpdatePowerIn", pg.UpdatePowerIn)


function pg:UpdatePowerOut(con)
	local pw_out = 0
	for k,v in ipairs(self:GetConsumers()) do
		pw_out = pw_out + (v.PowerRequired or 0)
	end

	self:SetPowerOut(pw_out)
end

pg:On("AddedConsumer", "UpdatePowerOut", pg.UpdatePowerOut)
pg:On("RemovedConsumer", "UpdatePowerOut", pg.UpdatePowerOut)

function pg:UpdateCapacity(con)
	local storage = pg.DefaultCapacity
	for k,v in ipairs(self:GetBatteries()) do
		storage = storage + v.PowerCapacity
	end

	if storage > 10000 then
		-- the 100 just ruins it,,,,,,,,,
		storage = storage - pg.DefaultCapacity
	end

	self:SetCapacity(storage)
	self:SetPower(math.min(self:GetPower(), self:GetCapacity()))
end

pg:On("AddedBattery", "UpdateCapacity", pg.UpdateCapacity)
pg:On("RemovedBattery", "UpdateCapacity", pg.UpdateCapacity)

local function indexer(nm)
	return function(...)
		return pg[nm] (...)
	end
end

-- list tracking

function pg:ConsumerAddList(e)
	if e.PowerRequired and e.PowerRequired > 0 then
		self:UnpowerEnt(e)
	else
		self:PowerEnt(e)
	end
end

function pg:ConsumerRemoveList(e)
	self:UnpowerEnt(e)

	self._UnpoweredEnts[e] = nil
	self._PoweredEnts[e] = nil
end

pg:On("AddedConsumer", "UpdateList", indexer("ConsumerAddList"))
pg:On("RemovedConsumer", "UpdateList", indexer("ConsumerRemoveList"))


function pg:PowerEnt(ent)
	self._PoweredEnts[ent] = true
	self._UnpoweredEnts[ent] = nil

	ent:SetPowered(true)

	if ent.OnPower then
		ent:OnPower()
	end
end

function pg:UnpowerEnt(ent)
	self._PoweredEnts[ent] = nil
	self._UnpoweredEnts[ent] = true

	ent:SetPowered(false)

	if ent.OnUnpower then
		ent:OnUnpower()
	end
end


function pg:Think()
	local base = self:GetBase()
	if not base or not self:GetValid() then return end

	local cur = self:GetPower()
	local add = self:GetPowerIn()
	local sub = self:GetPowerOut()

	if sub == 0 and add == 0 then return end

	local changes = {}

	if cur + add >= sub then
		-- we can upkeep every ent so dont bother and just set everyone as powered
		local diff = add - sub

		for ent, _ in pairs(self._UnpoweredEnts) do
			table.insert(changes, {ent, true})
		end

		if diff < 0 then
			self:TakePower(-diff)
		else
			self:AddPower(diff)
		end
	elseif cur + add < sub then
		-- we can upkeep only some entities
		local cur_sub = 0

		-- first we try to upkeep the already-powered ents
		for ent, _ in pairs(self._PoweredEnts) do
			if cur + add > cur_sub + ent.PowerRequired then
				cur_sub = cur_sub + ent.PowerRequired
			else
				-- we can't upkeep this ent
				table.insert(changes, {ent, false})
			end
		end

		if cur_sub < cur + add then
			-- we still have some power left to try and power some unpowered ents

			for ent, _ in pairs(self._UnpoweredEnts) do
				if cur + add > cur_sub + ent.PowerRequired then
					-- we can upkeep this ent
					table.insert(changes, {ent, true})
					cur_sub = cur_sub + ent.PowerRequired
				end
			end

			-- remainder goes into storage
			self:AddPower(add - cur_sub)
		end
	end

	for k, dat in ipairs(changes) do
		local ent = dat[1]
		if dat[2] then
			self:PowerEnt(ent)
		else
			self:UnpowerEnt(ent)
		end
	end

	for ent, _ in pairs(self._PoweredEnts) do
		if ent.PoweredThink then
			ent:PoweredThink(ent.PowerRequired)
		end
	end
end

function pg:UpdateNW(plys)
	self:GetNW():Network(true)
end

hook.Add("EntityEnteredBase", "NetworkGridEnts", function(base, ent)
	if not ent.IsBaseWars then return end

	local grid = base.PowerGrid
	if not grid then return end

	grid:AddEntity(ent)
end)

hook.Add("EntityExitedBase", "NetworkGridEnts", function(base, ent)
	if not ent.IsBaseWars then return end

	local grid = base.PowerGrid
	if not grid then print("exit - base didnt have power grid?", base) return end

	grid:RemoveEntity(ent)
end)


local lastThink = CurTime()

hook.Add("Tick", "PowerGrid_Tick", function()
	if CurTime() < lastThink then return end

	lastThink = CurTime() + pg.ThinkInterval

	for _, base in pairs(BaseWars.Bases.Bases) do
		local grid = base.PowerGrid
		if not grid then continue end

		xpcall(grid.Think, GenerateErrorer("PowergridThink"), grid)
	end
end)