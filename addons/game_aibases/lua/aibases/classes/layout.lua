--

local layout = AIBases.BaseLayout or Emitter:callable()
AIBases.BaseLayout = layout

ChainAccessor(layout, "Name", "Name")

function layout:Initialize(name)
	name = tostring(name)
	assert(isstring(name))

	self.Name = name
	self.Bricks = {}
	self.UIDBricks = {}
	self.TypeBricks = {}

	self.EnemySpots = {}
	self.Enemies = {}
	self.Navs = {}

	self._Valid = true
end

function layout:AddBrick(brick)
	assert(AIBases.IsBrick(brick))
	assert(not table.HasValue(self.Bricks, brick))

	local bs = self.TypeBricks[brick.type] or {}
	self.TypeBricks[brick.type] = bs
	assert(not table.HasValue(bs, brick))

	bs[#bs + 1] = brick
	self.Bricks[#self.Bricks + 1] = brick
	self.UIDBricks[brick.Data.uid] = brick
end

function layout:GetBrick(uid)
	return self.UIDBricks[uid]
end

function layout:GetBricksOfType(id)
	return self.TypeBricks[id]
end

function layout:IsValid()
	return self._Valid
end

ChainAccessor(layout, "_Valid", "Valid")

-- readNav = false -> don't load nav at all
-- readNav = true -> try loading nav but don't complain if it's not there
-- readNav = "string" -> read nav file from this filename

function layout:ReadFrom(fn, readNav)
	local navFn = isstring(readNav) and readNav or fn

	local dat = file.Read("aibases/layouts/" .. fn .. ".dat", "DATA")
	local lay = readNav ~= false and file.Read("aibases/layouts/" .. navFn .. "_nav.dat", "DATA")

	if not dat then print("no data @ ", "aibases/layouts/" .. fn .. ".dat") return end
	if not lay and not isbool(readNav) then print("no nav data @ ", "aibases/layouts/" .. navFn .. "_nav.dat") end

	self:Deserialize(dat, lay)

	return self
end

if SERVER then include("layout_ext_sv.lua") end