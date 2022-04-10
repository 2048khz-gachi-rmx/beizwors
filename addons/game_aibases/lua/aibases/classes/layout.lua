--

local layout = AIBases.BaseLayout or Emitter:extend()
AIBases.BaseLayout = layout

function layout:Initialize(name)
	name = tostring(name)
	assert(isstring(name))

	self.Name = name
	self.Bricks = {}
	self.Enemies = {}
end

function layout:AddBrick(brick)
	assert(AIBases.IsBrick(brick))
	assert(not table.HasValue(self.Bricks, brick))

	self.Bricks[#self.Bricks + 1] = brick
end

function layout:Spawn()
	for id, bs in pairs(self.Bricks) do
		for _, brick in ipairs(bs) do
			brick:Spawn()
		end
	end
end

function layout:Serialize()
	local bricks = AIBases.Storage.SerializeBricks(self.Bricks)
	local enemies = ""

	local header = string.char(bit.ToBytes(#bricks)) .. string.char(bit.ToBytes(#enemies))

	return header .. bricks
end

function layout:Deserialize(str)
	local data = str:sub(9)
	local brickSize = bit.ToInt(string.byte(str, 1, 4))
	local enemySize = bit.ToInt(string.byte(str, 5, 8))

	local brickData = data:sub(1, brickSize)
	local enemyData = data:sub(brickSize, brickSize + enemySize)

	local bricks = AIBases.Storage.DeserializeBricks(brickData)
	local enemies = {}

	self.Bricks = bricks
	self.Enemies = enemies
end

function layout:ReadFrom(fn)
	local dat = file.Read("aibases/layouts/" .. fn .. ".dat", "DATA")
	if not dat then print("no data @ ", "aibases/layouts/" .. fn .. ".dat") return end

	self:Deserialize(dat)
end