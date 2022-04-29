local sig = AIBases.LayoutBrick

AIBases.SignalBrick = AIBases.SignalBrick or sig:callable()
AIBases.SignalBrick.DataClass = sig.DataClass:callable({
	class = TYPE_STRING,
	pos = TYPE_VECTOR,
	angle = {TYPE_ANGLE, default = angle_zero},
	model = TYPE_STRING,
})

AIBases.SignalBrick.type = AIBases.BRICK_SIGNAL

function AIBases.SignalBrick:Build(ent)
	local new = AIBases.SignalBrick:new()

	local pos = ent:GetPos()
	local ang = ent:GetAngles()

	new.Data.pos = pos
	new.Data.ang = ang
	new.Data.class = ent:GetClass()
	new.Data.model = ent:GetModel()

	if new.Data.ang == angle_zero then new.ang = nil end

	return new
end

function AIBases.SignalBrick:PostBuild(others)
	print("post build")
end

function AIBases.SignalBrick:Remove()
	if IsValid(self.Ent) then self.Ent:Remove() end
end

function AIBases.SignalBrick:Spawn()
	if IsValid(self.Ent) then self.Ent:Remove() end

end

AIBases.SignalBrick:Register()