--

local brick = AIBases.LayoutBrick
AIBases.LootBrick = AIBases.LootBrick or brick:callable()
AIBases.LootBrick.DataClass = brick.DataClass:callable({
	model = TYPE_STRING,
	pos = TYPE_VECTOR,
	ang = TYPE_ANGLE,
	scale = {type = TYPE_NUMBER, default = 1},
	skin = {TYPE_NUMBER, default = 0},
	bgs = {TYPE_STRING, default = ""},
	pool = TYPE_STRING,
})

AIBases.LootBrick.type = AIBases.BRICK_LOOT

function AIBases.LootBrick:Spawn()
	self:Remove()

	local data = self.Data
	local ok, miss = data:Require()

	if not ok then
		errorNHf("AIBases.LootBrick:Spawn() : missing value `%s`.", miss or "?")
		return
	end

	local ent = ents.Create("lootable")
	self.Ent = ent

	-- timer.Simple(5, function() ent:Remove() end)

	ent:SetModel(data.model)
	ent:SetPos(data.pos)
	ent:SetAngles(data.ang)
	ent:SetLootPool(data.pool)

	ent.Brick = self

	ent:Spawn()
	ent:Activate()

	if data.skin ~= 0 then
		ent:SetSkin(data.skin)
	end

	if data.bgs ~= "" then
		ent:SetBodyGroups(data.bgs)
	end
end

function AIBases.LootBrick:Preload()
	local mdl = self.Data.model
	if mdl then Model(mdl) end
end

function AIBases.LootBrick:Remove()
	if IsValid(self.Ent) then self.Ent:Remove() end
end

function AIBases.LootBrick:Build(ent)
	local new = AIBases.LootBrick:new()
	local data = new.Data

	data.model = ent:GetModel()
	data.pos = ent:GetPos()
	data.ang = ent:GetAngles()

	if ent:GetSkin() ~= 0 then
		data.skin = ent:GetSkin()
	end

	local bgStr = ent:GetBodygroupsSet()
	if bgStr:match("[^0]") then
		data.bgs = bgStr
	end

	data.pool = ent:GetLootPool():GetName()

	return new
end

AIBases.LootBrick:Register()