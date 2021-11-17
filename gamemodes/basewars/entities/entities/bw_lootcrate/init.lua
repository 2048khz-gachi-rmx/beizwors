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
