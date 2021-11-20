include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

function ENT:Init(me)

end

function ENT:Think()
	self:NextThink(CurTime() + 1)
	return true
end

local dropBounds = Vector(8, 8, 8)
local zoffset = Vector(0, 0, dropBounds.z)
local xyBounds = Vector(dropBounds.x, dropBounds.y, 0)

function ENT:Use(ply)
	if self:GetLockLevel() ~= 0 then
		print("cant unlock: lock isnt 0")
		return
	end

	if not self.Ready then print("uninitialized fuck you") return end -- can't use uninitialized

	local dropDist = 64
	local ignoreTable = player.GetAll()
	table.insert(ignoreTable, self)

	for k,v in pairs(self.Storage:GetItems()) do
		local drop = ents.Create("dropped_item")
		table.insert(ignoreTable, drop)

		local dropDir = math.random() * 360
		local off = Vector(
			math.cos(math.rad(dropDir)) * dropDist,
			math.sin(math.rad(dropDir)) * dropDist,
			0)

		local dropPos

		self.Storage:RemoveItem(v, true)
		v:SetSlot(nil)

		-- trace in a random direction on the x,y plane

		local sPos = self:GetPos() + self:OBBCenter()

		local tr = util.TraceHull({
			mins = -xyBounds,
			maxs = xyBounds,

			start = sPos,
			endpos = sPos + off,
			filter = ignoreTable,
		})

		if tr.Hit then
			dropPos = tr.HitPos
		else
			dropPos = sPos + off
		end

		-- trace downwards
		local tr = util.TraceHull({
			mins = -dropBounds,
			maxs = dropBounds,

			start = dropPos + zoffset,
			endpos = dropPos - Vector(0, 0, 4096),
			filter = ignoreTable,
		})

		if tr.Hit then
			dropPos = tr.HitPos
		end

		drop:SetItem(v)
		drop:SetDropOrigin(self:GetPos())
		drop:Spawn()
		drop:SetPos(dropPos)
		drop:Timer(2, 3, 1, function() drop:Remove() end)
		drop:Activate()
	end

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

	print("picked size:", sz)
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
