include("shared.lua")
AddCSLuaFile("shared.lua")

function ENT:CLInit()

end

local dropBounds = Vector(8, 8, 8)
local zoffset = Vector(0, 0, dropBounds.z)
local xyBounds = Vector(dropBounds.x, dropBounds.y, 0)

local rand = math.random()
local lr = CurTime()

function ENT:Draw()
	if CurTime() - lr > 0.7 then rand = math.random() lr = CurTime() end

	self:DrawModel()
	do return end

	local a = self:GetAngles()
	local dA = a:Forward() + a:Up() + a:Right()

	local sPos = self:GetPos() + self:OBBCenter() * dA + zoffset
	render.DrawWireframeBox(sPos, Angle(), -dropBounds, dropBounds, color_white)

	local ignoreTable = player.GetAll()
	table.insert(ignoreTable, self)


	local dropDist = 48
	local dropHeight = 64

	local dropDir = rand * 360
	local off = Vector(
		math.cos(math.rad(dropDir)) * dropDist,
		math.sin(math.rad(dropDir)) * dropDist,
		0)

	local lastPos = sPos
	render.SetColorMaterialIgnoreZ()

	local segs = 32
	local hitPos

	for i=0, 1, 1 / segs do
		i = Ease(i, 0.7)

		local newPos = LerpVector(i, sPos, sPos + off)
		newPos[3] = newPos[3] + math.sin(i * math.pi) * dropHeight

		render.DrawLine(lastPos, newPos, color_white)
		local tr = util.TraceHull({
			mins = -dropBounds,
			maxs = dropBounds,

			start = lastPos,
			endpos = newPos,
			filter = ignoreTable,
		})

		if tr.Hit or i == 1 then
			render.DrawWireframeBox(tr.HitPos, Angle(), -dropBounds, dropBounds,
				tr.Hit and Colors.Red or Colors.Sky)
		end

		render.DrawSphere(tr.HitPos, 4, 8, 8, tr.Hit and Colors.Red or Colors.Sky)

		if tr.Hit then hitPos = tr.HitPos break end
		lastPos = newPos
	end

	-- didn't collide with anything; trace downwards till ground

	local tr = util.TraceHull({
		mins = -dropBounds * 0.8,
		maxs = dropBounds * 0.8,

		start = hitPos or lastPos,
		endpos = (hitPos or lastPos) - Vector(0, 0, 4096),
		filter = ignoreTable,
	})

	render.DrawWireframeBox(tr.HitPos, Angle(), -dropBounds, dropBounds, color_white)
	if tr.Hit then
		dropPos = tr.HitPos
		render.DrawSphere(dropPos, 4, 8, 8, Colors.Yellowish)
	else
		render.DrawSphere(dropPos, 4, 8, 8, Colors.Sky)
	end

end