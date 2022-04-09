--

local layout = AIBases.BaseLayout or Emitter:extend()
AIBases.BaseLayout = layout

function layout:Initialize(base, name)
	name = tostring(name)
	assert(isstring(name))

	self.Bricks = {}
	self.Enemies = {}
end

function layout:AddBrick(brick)
	assert(AIBases.IsBrick(brick))
	assert(not table.HasValue(self.Bricks, brick))

	self.Bricks[#self.Bricks + 1] = brick
end