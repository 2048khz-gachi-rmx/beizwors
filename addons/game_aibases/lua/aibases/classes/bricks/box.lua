local brick = AIBases.LayoutBrick

AIBases.BoxBrick = AIBases.BoxBrick or brick:callable()
AIBases.BoxBrick.DataClass = brick.DataClass:callable({
	mins = TYPE_VECTOR,
	maxs = TYPE_VECTOR,
	angle = {TYPE_ANGLE, default = angle_zero},
})

AIBases.BoxBrick.type = AIBases.BRICK_BOX

function AIBases.BoxBrick:Build(ent)
	local new = AIBases.BoxBrick:new()
	local mins, maxs = ent:GetCollisionBounds()
	local pos = ent:GetPos()
	mins:Add(pos) maxs:Add(pos)

	new.Data.mins = mins
	new.Data.maxs = maxs
	new.angle = ent:GetAngles()

	if new.angle == angle_zero then new.angle = nil end

	return new
end

function AIBases.BoxBrick:Spawn()
	if IsValid(self.Ent) then self.Ent:Remove() end

	local mins, maxs = self.Data.mins, self.Data.maxs
	local ang = self.Data.angle

	local woll = ents.Create("aib_wall")
	--timer.Simple(5, function() woll:Remove() end)
	self.Ent = woll

	local center = (mins + maxs) / 2
	mins = mins - center
	maxs = maxs - center

	woll:SetPos(center)

	woll:Spawn()
	woll:InitPhys(mins, maxs)
	woll:SetAngles(ang)
	woll:Activate()
end

AIBases.BoxBrick:Register()