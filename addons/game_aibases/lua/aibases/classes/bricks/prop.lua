--

local brick = AIBases.LayoutBrick
AIBases.PropBrick = brick:callable({
	model = TYPE_STRING,
	pos = TYPE_VECTOR,
	ang = TYPE_ANGLE,
	scale = {type = TYPE_NUMBER, default = 1}
})

AIBases.PropBrick.type = AIBases.BRICK_PROP

function AIBases.PropBrick:Spawn()
	local ok, miss = self:Require()

	if not ok then
		errorNHf("AIBases.PropBrick:Spawn() : missing value `%s`.", miss or "?")
		return
	end

	print("spawning propbrick...")
end

function AIBases.PropBrick:Build(ent)
	local new = AIBases.PropBrick:new()

	new.model = ent:GetModel()
	new.pos = ent:GetPos()
	new.ang = ent:GetAngles()
	new.scale = ent:GetModelScale()
	if new.scale == 1 then new.scale = nil end

	return new
end

local b = AIBases.PropBrick()

b.pos = vector_origin
b.ang = angle_zero
b.model = ""

b:Spawn()
