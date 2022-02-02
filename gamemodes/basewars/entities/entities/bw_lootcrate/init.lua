include("shared.lua")
AddCSLuaFile("shared.lua")

include("generation.lua")
AddCSLuaFile("cl_init.lua")

CrateRespawnTime = 30

function ENT:Init(me)
	ActiveLootCrates[#ActiveLootCrates + 1] = self
	self.TimesUsed = 0
	self.LastUse = 0
	self.TimesToOpen = 4
end

function ENT:OnRemove()
	table.RemoveByValue(ActiveLootCrates, self)
	self:RespawnIn(1) -- unintended removal if RespawnIn actually works
end

function ENT:Think()
	self:NextThink(CurTime() + 1)
	return true
end

function ENT:RespawnIn(time)
	if self.SpawningElsewhere then return end
	self.SpawningElsewhere = true

	LootCratesAwaitingRespawn = LootCratesAwaitingRespawn + 1
	time = time or CrateRespawnTime
	timer.Simple(time, function()
		LootCratesAwaitingRespawn = LootCratesAwaitingRespawn - 1
		LootCratesSpawn(1)
	end)
end

function ENT:RemoveRespawnless()
	self.SpawningElsewhere = true
	self:Remove()
end

local dropBounds = Vector(8, 8, 8)
local zoffset = Vector(0, 0, dropBounds.z)
local xyBounds = Vector(dropBounds.x, dropBounds.y, 0)

local thanks_valve = {1, 3, 4}

function ENT:PickUseSound(t)
	local mdl = self:GetModel():lower()

	if mdl:match("cardboard_box") or mdl:match("item_item_crate") then
		return ("physics/cardboard/cardboard_box_impact_hard%d.wav")
			:format(math.random(1, 7))
	end

	if mdl:match("briefcase") or mdl:match("suitcase") then
		return ("weapons/357/357_reload1.wav")
			:format( thanks_valve[math.random(1, 3)] )
	end
end

--[[
weapons/arccw/c4/key_press1.wav  1 to 7
]]
function ENT:PickOpenSound()
	local mdl = self:GetModel():lower()

	if mdl:match("cardboard_box") or mdl:match("item_item_crate") then
		return ("physics/cardboard/cardboard_box_break%d.wav")
			:format(math.random(1, 3))
	end

	if mdl:match("briefcase") or mdl:match("suitcase") then
		-- weapons/arccw_mifl/fas2/1911/1911_sliderelease.wav
		-- weapons/arccw_mifl/fas2/g3/g3_boltforward.wav
		-- weapons/arccw_mifl/fas2/m24/m24_boltup.wav <- plenty of sounds
		return "weapons/357/357_spin1.wav"
	end
end

function ENT:Use(ply)
	if self:GetLockLevel() ~= 0 then
		print("cant unlock: lock isnt 0")
		return
	end

	-- can't use uninitialized
	if not self.Ready then
		print("uninitialized fuck you")
		return
	end

	local sinceUse = CurTime() - self.LastUse
	local subUses = math.max(0, sinceUse - 3)

	local times = math.floor( math.max(0, self.TimesUsed - subUses) )
	self.LastUse = CurTime()

	self.TimesUsed = times + 1

	if self.TimesUsed < self.TimesToOpen then
		local snd, pitch = self:PickUseSound(self.TimesUsed)
		if not snd then return end

		self:EmitSound(snd, 60, pitch, 0.8)
		return
	end

	local openSnd = self:PickOpenSound()
	if openSnd then
		self:EmitSound(openSnd, 75, pitch, 1)
	end

	local ignoreTable = player.GetAll()
	table.insert(ignoreTable, self)

	local a = self:GetAngles()
	local dA = a:Forward() + a:Up() + a:Right()
	local sPos = self:GetPos() + self:OBBCenter() * dA + zoffset

	local del = 0

	local sort = {}

	for k,v in pairs(self.Storage:GetItems()) do
		sort[#sort + 1] = v
	end

	table.sort(sort, function(a, b)
		local r1, r2 = a:GetRarity(), b:GetRarity()
		r1 = r1 and r1:GetRarity()
		r2 = r2 and r2:GetRarity()

		if not r1 and r2 then return false end
		if r1 and not r2 then return true end

		return r1 < r2
	end)

	for k,v in ipairs(sort) do
		local drop = ents.Create("dropped_item")
		table.insert(ignoreTable, drop)

		local dropDist = 48
		local dropHeight = 64

		local dropDir = math.random() * 360
		local off = Vector(
			math.cos(math.rad(dropDir)) * dropDist,
			math.sin(math.rad(dropDir)) * dropDist,
			0)

		local lastPos = sPos

		local segs = 32
		local hitPos

		for i=0, 1, 1 / segs do
			local newPos = LerpVector(i, sPos, sPos + off)
			newPos[3] = newPos[3] + math.sin(i * math.pi) * dropHeight

			local tr = util.TraceHull({
				mins = -dropBounds,
				maxs = dropBounds,

				start = lastPos,
				endpos = newPos,
				filter = ignoreTable,
			})

			if tr.Hit then
				hitPos = tr.HitPos
				break
			end

			lastPos = newPos
		end

		-- trace downwards till ground
		hitPos = hitPos or lastPos

		local tr = util.TraceHull({
			mins = -dropBounds * 0.8,
			maxs = dropBounds * 0.8,

			start = hitPos,
			endpos = hitPos - Vector(0, 0, 4096),
			filter = ignoreTable,
		})

		local dropPos = hitPos

		if tr.Hit then
			dropPos = tr.HitPos
		end

		self.Storage:RemoveItem(v, true)
		v:SetSlot(nil)

		local pos = self:GetPos()

		timer.Simple(del, function()
			drop:SetCreatedTime(CurTime())
			drop:SetItem(v)
			drop:SetDropOrigin(pos)
			drop:Spawn()
			drop:SetPos(dropPos)
			drop:Activate()
			drop:PlayDropSound()
		end)

		del = del + 0.4 + math.random() * 0.3
	end

	self:RespawnIn()
	self:Remove()
end



function ENT:ChangeProperties(ply)
	local typ = ply:KeyDown(IN_WALK)
	if typ then
		for k,v in RandomPairs(self.TypeInfo) do
			if k ~= self.CrateType then
				self.CrateType = k

				local models, newSize = table.Random(v.models)
				self.Size = newSize
				self.Model = models[math.random(#models)]
				self:SetModel(self.Model)
				self:PhysicsInit(SOLID_VPHYSICS)
				break
			end
		end

		self:SetPos(self:GetPos() - self:OBBCenter())
		return
	end

	local sz = self.Size
	local en = 999

	if self.ModelCopies and table.IsEmpty(self.ModelCopies) then
		local start = 0
		for k,v in pairs(self.SizeInfo) do
			if v == sz then
				start = k
			end
		end

		for i=1, #self.SizeInfo + 1 do
			start = (start % (#self.SizeInfo + 1)) + 1
			local newSz = self.SizeInfo[start]
			if self:GetTypeInfo().models[newSz] then
				sz = newSz
				break
			end
		end

		self.ModelCopies = nil
	end

	self.Size = sz

	if not self.ModelCopies then
		self.ModelCopies = table.Copy(self:GetTypeInfo().models[self.Size])
		self.ModelNum = 1

		PrintTable(self.ModelCopies)
	end

	print("model: ", self.ModelNum, "/", self.ModelNum + table.Count(self.ModelCopies) - 1)
	self.Model = self.ModelCopies[self.ModelNum]
	self.ModelCopies[self.ModelNum] = nil

	self.ModelNum = self.ModelNum + 1

	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_VPHYSICS)

	self:SetPos(self:GetPos() - self:OBBCenter())
end

PermaLootCrates = PermaLootCrates or {}

function ENT:AddPerma()
	local saveTbl = {
		self:GetPos(), self:GetAngles(),
		self.CrateType, self.Size, self:GetModel()
	}

	if self.SavedKey then
		PermaLootCrates[self.SavedKey] = saveTbl
	else
		local k = table.insert(PermaLootCrates, saveTbl)
		self.SavedKey = k
	end
end

function ENT:RemovePerma()
	if not self.SavedKey then return end
	PermaLootCrates[self.SavedKey] = nil
	self:Remove()
end

function ENT:CanTool(ply, tr, name, tool)
	if name == "permaprops" and ply:IsSuperAdmin() then
		if ply:KeyDown(IN_ATTACK2) then
			self:RemovePerma()
		elseif ply:KeyDown(IN_RELOAD) then
			self:ChangeProperties(ply)
			self.SavedKey = nil
		else
			self:AddPerma()
		end

		return false
	end
end
