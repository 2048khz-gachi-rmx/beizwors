include("shared.lua")
AddCSLuaFile("shared.lua")

function ENT:CLInit()

end

local dropBounds = Vector(8, 8, 8)
local rand = math.random()
local lr = CurTime()

function ENT:Draw()
	if CurTime() - lr > 0.1 then rand = math.random() lr = CurTime() end

	self:DrawModel()
	do return end

	local sPos = self:GetPos() + self:OBBCenter()

	local ignoreTable = player.GetAll()
	table.insert(ignoreTable, self)


	local dropDist = 32
	local dropDir = rand * 360
	local off = Vector(
		math.cos(math.rad(dropDir)) * dropDist,
		math.sin(math.rad(dropDir)) * dropDist,
		0)

	local tr = util.TraceHull({
		mins = -dropBounds,
		maxs = dropBounds,

		start = sPos,
		endpos = sPos + off,
		filter = ignoreTable,
	})

	render.SetColorMaterialIgnoreZ()
	if tr.Hit then
		dropPos = tr.HitPos
		render.DrawSphere(dropPos, 4, 8, 8, Colors.Red)
	else
		dropPos = sPos + off
		render.DrawSphere(dropPos, 4, 8, 8, Colors.Sky)
	end


	-- trace downwards

	local ae = Vector(0, 0, dropBounds.z)
	local tr = util.TraceHull({
		mins = -dropBounds,
		maxs = dropBounds,

		start = dropPos + ae,
		endpos = dropPos - Vector(0, 0, 4096),
		filter = ignoreTable,
	})

	render.DrawWireframeBox(dropPos + ae, self:GetAngles(), -dropBounds, dropBounds, color_white)
	if tr.Hit then
		dropPos = tr.HitPos
		render.DrawSphere(dropPos, 4, 8, 8, Colors.Red)
	else
		render.DrawSphere(dropPos, 4, 8, 8, Colors.Sky)
	end

end