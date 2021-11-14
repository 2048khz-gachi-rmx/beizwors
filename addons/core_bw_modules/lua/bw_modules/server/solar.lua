BaseWars.Solar = BaseWars.Solar or {}
local sol = BaseWars.Solar

BaseWars.Solar.SkylessPower = 4
BaseWars.Solar.SkyPower = 10

local rayPos = Vector(2.4543991088867, -32.136005401611, 3.2566497325897)
local tout = {}
local tdat = {output = tout}

local skylessPower = BaseWars.Solar.SkylessPower
local skyPower = BaseWars.Solar.SkyPower

function sol:Initialize()
	self.BaseHandle = ents.Create("bw_invismarker")
	local bh = self.BaseHandle

	--bh:SetModel("models/hunter/blocks/cube6x6x6.mdl")
	bh:SetParent(self)
	bh.SolarAttachment = self

	bh.CustomOBB = {
		Vector(-100, -100, -100),
		Vector(100, 100, 100),
	}

	bh.Model = false
	bh:Spawn()
	bh:Activate()

	local horOff = bh:OBBCenter() - self:OBBCenter()
	horOff.z = 0

	--[[
	local bhMin, bhMax = unpack(bh.CustomOBB)
	local vertOff = bhMax.z - bhMin.z
	local horOff = Vector()

	horOff[1] = -(bhMax.z + bhMin.z) / 2
	horOff[2] = (bhMax.y + bhMin.y) / 2
	horOff[3] = -vertOff / 2
	]]

	bh:SetPos(horOff)

	self._LastThink = 0
	self.ForceUpdate = true
	self:Think()
	self.ForceUpdate = false
end

function sol:Think()
	--if CurTime() - self._LastThink < 0.25 then return end
	self._LastThink = CurTime()

	local grid
	local bases = self:BW_GetAllBases()
	local did = false

	for k,v in ipairs(bases) do
		if v:IsEntityOwned(self) then
			self:SetBaseAccess(true)
			grid = v:GetPowerGrid()
			did = true
			break
		end
	end

	if not did then
		self:SetBaseAccess(false)
	end

	--if not grid then return end

	local pos = self:LocalToWorld(rayPos)
	tdat.output = tout
	tdat.start = pos
	tdat.endpos = pos + self:GetAngles():Up() * 16384
	tdat.filter = {self}

	util.TraceLine(tdat)
	local isSky = tout.HitSky

	if isSky then
		local upd = self.ForceUpdate or self.PowerGenerated ~= skyPower

		if grid then
			self.PowerGenerated = skyPower

			if upd then
				grid:UpdatePowerIn()
			end
		end
	else
		local upd = grid and self.ForceUpdate or self.PowerGenerated ~= skylessPower
		if grid then
			self.PowerGenerated = skylessPower

			if upd then
				grid:UpdatePowerIn()
			end
		end
	end

	self:SetSunAccess(isSky)
	self:NextThink(CurTime() + 0.35)
	return true
end

local function entToBoth(ent)
	if not ent:IsValid() or (not ent.SolarAttachment and ent:GetClass() ~= "bw_gen_solar") then return end

	local solar = ent:GetClass() == "bw_gen_solar" and ent or ent.SolarAttachment
	local handle = ent.SolarAttachment and ent or ent.BaseHandle

	return solar, handle
end

hook.Add("EntityExitZone", "SolarPanelAttach", function(zone, ent)
	local solar, handle = entToBoth(ent)
	if not solar then return end

	local base = zone:GetBase()
	local ents = base:GetEntities()
	-- this hook runs before the entity exits; the exiter will still be in the list

	-- if the solar exited with handle still inside, don't remove

	solar.ActuallyInside = solar.ActuallyInside and ent ~= solar


	if ent == solar and ents[handle] then
		return false
	end

	if ent == handle and not solar.ActuallyInside and ents[solar] then
		ents[handle] = nil
		solar:ExitZone(zone)
	end
end)

hook.Add("EntityEnteredZone", "SolarPanelAttach", function(zone, ent)
	local solar, handle = entToBoth(ent)
	if not solar then return end

	solar.ActuallyInside = solar.ActuallyInside or ent == solar

	local base = zone:GetBase()
	local ents = base:GetEntities()

	-- if the handle entered with no solar inside, add the solar as well
	if ent == handle and not ents[solar] then
		local inside = solar.ActuallyInside
		solar:EnterZone(zone)
		solar.ActuallyInside = inside
	end
end)