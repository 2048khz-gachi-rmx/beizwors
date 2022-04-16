--

local layout = AIBases.BaseLayout or Emitter:extend()
AIBases.BaseLayout = layout

function layout:Initialize(name)
	name = tostring(name)
	assert(isstring(name))

	self.Name = name
	self.Bricks = {}
	self.EnemySpots = {}
	self.Enemies = {}
	self.Navs = {}
end

function layout:AddBrick(brick)
	assert(AIBases.IsBrick(brick))
	assert(not table.HasValue(self.Bricks, brick))

	self.Bricks[#self.Bricks + 1] = brick
end

function layout:Spawn()
	if self.LuaNavs then
		AIBases.ConstructNavs(self.LuaNavs)
	end

	for id, bs in pairs(self.Bricks) do
		for _, brick in ipairs(bs) do
			brick:Spawn()
		end
	end
end

function layout:Serialize()
	local bricks = AIBases.Storage.SerializeBricks(self.Bricks)
	local enemies = ""--AIBases.Storage.SerializeEnemies(self.Enemies)

	local header = string.char(bit.ToBytes(#bricks)) .. string.char(bit.ToBytes(#enemies))

	return header .. bricks .. enemies
end

function layout:Deserialize(str, nav)
	local data = str:sub(9)
	local brickSize = bit.ToInt(string.byte(str, 1, 4))
	local enemySize = bit.ToInt(string.byte(str, 5, 8))

	local brickData = data:sub(1, brickSize)
	local enemyData = data:sub(brickSize + 1, brickSize + enemySize)

	local bricks = AIBases.Storage.DeserializeBricks(brickData)
	local enemies = AIBases.Storage.DeserializeEnemies(enemyData)

	self.Bricks = bricks
	self.EnemySpots = enemies

	if nav then
		self.LuaNavs = AIBases.Storage.DeserializeNavs(nav)
	end
end

function layout:ReadFrom(fn, layFn)
	local dat = file.Read("aibases/layouts/" .. fn .. ".dat", "DATA")
	local lay = file.Read("aibases/layouts/" .. (layFn or fn) .. "_nav.dat", "DATA")

	if not dat then print("no data @ ", "aibases/layouts/" .. fn .. ".dat") return end
	if not lay then print("no nav data @ ", "aibases/layouts/" .. (layFn or fn) .. "_nav.dat") end

	self:Deserialize(dat, lay)
end