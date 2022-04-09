local brick = AIBases.LayoutBrick
AIBases.BoxBrick = brick:callable({
	mins = TYPE_VECTOR,
	maxs = TYPE_VECTOR,
	angle = TYPE_ANGLE,
})

AIBases.BoxBrick.type = AIBases.BRICK_BOX

function AIBases.BoxBrick:Build(ent)
	local new = AIBases.BoxBrick:new()
	local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
	local pos = ent:GetPos()
	mins:Add(pos) maxs:Add(pos)

	new.mins = mins
	new.maxs = maxs
	new.angle = ent:GetAngles()

	return new
end