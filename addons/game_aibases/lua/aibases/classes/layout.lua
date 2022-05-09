--

local layout = AIBases.BaseLayout or Emitter:callable()
AIBases.BaseLayout = layout

function layout:Initialize(name)
	name = tostring(name)
	assert(isstring(name))

	self.Name = name
	self.Bricks = {}
	self.UIDBricks = {}
	self.EnemySpots = {}
	self.Enemies = {}
	self.Navs = {}
end

function layout:AddBrick(brick)
	assert(AIBases.IsBrick(brick))
	assert(not table.HasValue(self.Bricks, brick))

	self.Bricks[#self.Bricks + 1] = brick
	self.UIDBricks[brick.Data.uid] = brick
end

function layout:GetBrick(uid)
	return self.UIDBricks[uid]
end

function layout:GetBricksOfType(id)
	return self.Bricks[id]
end

function layout:ReadFrom(fn, layFn)
	local dat = file.Read("aibases/layouts/" .. fn .. ".dat", "DATA")
	local lay = file.Read("aibases/layouts/" .. (layFn or fn) .. "_nav.dat", "DATA")

	if not dat then print("no data @ ", "aibases/layouts/" .. fn .. ".dat") return end
	if not lay then print("no nav data @ ", "aibases/layouts/" .. (layFn or fn) .. "_nav.dat") end

	self:Deserialize(dat, lay)

	return self
end

if SERVER then include("layout_ext_sv.lua") end