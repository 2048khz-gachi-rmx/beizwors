local brick = AIBases.LayoutBrick

AIBases.EnemyBrick = AIBases.EnemyBrick or brick:callable()
AIBases.EnemyBrick.DataClass = brick.DataClass:callable({
	pos = TYPE_VECTOR,
	ang = TYPE_ANGLE,
	wep = {TYPE_STRING, "random"},
	tier = {TYPE_NUMBER, 1},
	model = {TYPE_STRING, ""},
	patrol = {TYPE_TABLE, {}},
})

AIBases.EnemyBrick.type = AIBases.BRICK_ENEMY

function AIBases.EnemyBrick:Build(ent)
	local new = AIBases.EnemyBrick:new()
	local pos = ent:GetPos()
	local ang = ent:GetAngles()
	local wep

	if ent.ForceWeapon then
		wep = ent.ForceWeapon
	elseif IsValid(ent:GetCurrentWeapon()) then
		wep = ent:GetCurrentWeapon():GetClass()
	end

	new.Data.pos = pos
	new.Data.ang = ang

	if wep then new.Data.wep = wep end
	if ent.Tier ~= 1 then new.Data.tier = ent.Tier end
	if ent.ModelOverride then new.Data.model = ent.ModelOverride end

	local tempPatrol = bld.PNW:Get(ent) or ent.PatrolRoute
	if tempPatrol then
		new.Data.patrol = tempPatrol
	end

	return new
end

function AIBases.EnemyBrick:Remove()
	if IsValid(self.Ent) then self.Ent:Remove() end
end

function AIBases.EnemyBrick:Spawn()
	self:Remove()

	local bot = ents.Create("aib_bot")
	self.Ent = bot

	bot:SetPos(self.Data.pos)
	bot:SetAngles(self.Data.ang)

	if self.Data.model ~= "" then
		bot:SetModel(self.Data.model)
		bot.ModelOverride = self.Data.model
	end

	bot.ForceWeapon = self.Data.wep
	bot.Tier = self.Data.tier
	bot.Brick = self
	bot.PatrolRoute = self.Data.patrol
	bot:Spawn()
end

AIBases.EnemyBrick:Register()