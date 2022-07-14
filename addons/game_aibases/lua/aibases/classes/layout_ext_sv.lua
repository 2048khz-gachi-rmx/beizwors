local layout = AIBases.BaseLayout

function layout:SpawnPrioritySort(bricks)
	table.sort(bricks, function(a, b)
		return a.type > b.type -- reversed; spawn begins from the top
	end)
end

function layout:Spawn()
	if self.LuaNavs then
		AIBases.ConstructNavs(self.LuaNavs)
	end

	local toSpawn = {}
	for id, bs in pairs(self.TypeBricks) do
		for _, brick in ipairs(bs) do
			toSpawn[#toSpawn + 1] = brick
		end
	end

	self:SpawnPrioritySort(toSpawn)

	for i=#toSpawn, 1, -1 do
		toSpawn[i]:Spawn(self)
	end

	for i=#toSpawn, 1, -1 do
		toSpawn[i]:PostSpawn(self)
	end

	self.SlowSpawning = nil
end

Timerify(layout)

function layout:SlowSpawn(msTimeout)
	local bricksToSpawn = {}
	local spawned = {}
	msTimeout = tonumber(msTimeout) or 3
	msTimeout = msTimeout / 1000

	for id, bs in pairs(self.TypeBricks) do
		for _, brick in ipairs(bs) do
			bricksToSpawn[#bricksToSpawn + 1] = brick
		end
	end

	self:SpawnPrioritySort(bricksToSpawn)

	local pr = Promise()

	self._ssQueue = bricksToSpawn
	self._ssDone = spawned
	self._ssProm = pr
	self.SlowSpawning = true

	if self.LuaNavs then
		AIBases.ConstructNavs(self.LuaNavs)
	else
		printf("!!! Layout `%s` has no lua navs !!!", self.Name)
	end

	self:Timer("SlowSpawn", 0, "0", function()
		self:_DoSlowSpawnCycle(msTimeout)
	end)

	return pr:Then(function(_, bs)
		for k,v in ipairs(bs) do
			v:PostSpawn()
		end

		return bs
	end)
end

function layout:_FinishSlowSpawn(ok)
	local pr = self._ssProm
	self:RemoveTimer("SlowSpawn")
	pr:Decide(ok == nil or ok, self._ssDone)
end

function layout:_DoSlowSpawnCycle(ms)
	local toSpawn, done = self._ssQueue, self._ssDone

	if #toSpawn == 0 then
		self:_FinishSlowSpawn(true)
		return
	end

	if not self.SlowSpawning then
		self:_FinishSlowSpawn(false)
		self:RemoveTimer("SlowSpawn")
		return
	end

	local s1 = SysTime()
	for i=#toSpawn, 1, -1 do
		local passed = SysTime() - s1
		if passed > ms then break end

		toSpawn[i]:Spawn()
		table.insert(done, toSpawn[i])
		toSpawn[i] = nil
	end
end

function layout:Serialize()
	local bricks = AIBases.Storage.SerializeBricks(self.Bricks)
	local enemies = ""--AIBases.Storage.SerializeEnemies(self.Enemies)

	local header = string.char(bit.ToBytes(#bricks)) .. string.char(bit.ToBytes(#enemies))

	return header .. bricks .. enemies
end

function layout:Despawn()
	self:Emit("Despawn")
	for k,v in pairs(self.Bricks) do
		v:Remove()
	end

	if self.LuaNavs then
		for k,v in pairs(self.LuaNavs) do
			v:Remove()
		end
	end
end

function layout:Deserialize(str, nav)
	local data = str:sub(9)
	local brickSize = bit.ToInt(string.byte(str, 1, 4))
	local enemySize = bit.ToInt(string.byte(str, 5, 8))

	local brickData = data:sub(1, brickSize)
	local enemyData = data:sub(brickSize + 1, brickSize + enemySize)

	local bricks = AIBases.Storage.DeserializeBricks(brickData)
	local enemies = AIBases.Storage.DeserializeEnemies(enemyData)

	for typ, bs in pairs(bricks) do
		for _, brick in pairs(bs) do
			self:AddBrick(brick)
		end
	end

	self.EnemySpots = enemies

	if nav then
		self.LuaNavs = AIBases.Storage.DeserializeNavs(nav)
	end
end

function layout:MarkAll(ply)
	assert(IsPlayer(ply))

	for id, bs in pairs(self.TypeBricks) do
		for _, brick in pairs(bs) do
			if not IsValid(brick.Ent) then print("no ent for brick", brick, brick.Data.uid) continue end
			AIBases.Builder.AddBrick(ply, brick.Ent, id)
		end
	end
end

