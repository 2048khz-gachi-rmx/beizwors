--
print("hi")

local base = AIBases.AIBase or Emitter:extend()
AIBases.AIBase = base

base.LockStruct = Struct:extend({
	model = {type = TYPE_STRING, default = "models/props_borealis/door_wheel001a.mdl"},
	pos = TYPE_VECTOR,
	ang = TYPE_ANGLE,
})

ChainAccessor(base.LockStruct, "pos", "Pos")
ChainAccessor(base.LockStruct, "ang", "Angles")
ChainAccessor(base.LockStruct, "ang", "Ang")
ChainAccessor(base.LockStruct, "ang", "Angle")

function base:Initialize(name)
	name = tostring(name)
	assert(isstring(name))

	self.Layout = AIBases.BaseLayout:new(self, name)
end

ChainAccessor(base, "Lock", "Lock")

function base:CreateLock()
	self.Lock = base.LockStruct:new()

	return self.Lock
end


function base:Finish()
	assert(self.Lock and self.Lock:Requre(), "incorrect lock")

end