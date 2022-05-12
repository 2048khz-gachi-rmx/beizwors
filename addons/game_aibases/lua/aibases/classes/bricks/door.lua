-- DOOR STUCK

local brick = AIBases.LayoutBrick

AIBases.DoorBrick = AIBases.DoorBrick or brick:callable()

local exTbl = {
	pos = TYPE_VECTOR,
	ang = TYPE_ANGLE,
	mins = TYPE_VECTOR,
	maxs = TYPE_VECTOR
}


AIBases.DoorBrick.DataClass = brick.DataClass:callable(exTbl)

AIBases.DoorBrick.type = AIBases.BRICK_DOOR

function AIBases.DoorBrick:Build(ent)
	local new = AIBases.DoorBrick:new()
	local pos = ent:GetPos()
	local ang = ent:GetAngles()

	new.Data.pos = pos
	new.Data.ang = ang

	local mins, maxs = ent:GetBound1(), ent:GetBound2()
	new.Data.mins = mins
	new.Data.maxs = maxs

	return new
end

function AIBases.DoorBrick:Remove()
	if IsValid(self.Ent) then self.Ent:Remove() end
end

function AIBases.DoorBrick:Spawn()
	self:Remove()

	local door = ents.Create("bw_morph_door")
	self.Ent = door

	door:SetPos(self.Data.pos)
	door:SetAngles(self.Data.ang)

	door.Brick = self
	door:Spawn()

	door:BoksFiziks(self.Data.mins, self.Data.maxs)
	door:Install()
end

AIBases.DoorBrick:Register()