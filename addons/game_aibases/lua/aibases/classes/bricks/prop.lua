--

local brick = AIBases.LayoutBrick
AIBases.PropBrick = AIBases.PropBrick or brick:callable()
AIBases.PropBrick.DataClass = brick.DataClass:callable({
	model = TYPE_STRING,
	pos = TYPE_VECTOR,
	ang = TYPE_ANGLE,
	scale = {type = TYPE_NUMBER, default = 1},
	class = {TYPE_STRING, default = "prop_physics"},
	freeze = {TYPE_BOOL, default = true},
	skin = {TYPE_NUMBER, default = 0},
	bgs = {TYPE_STRING, default = ""},
})

AIBases.PropBrick.type = AIBases.BRICK_PROP

function AIBases.PropBrick:Spawn()
	self:Remove()

	local data = self.Data
	local ok, miss = data:Require()

	if not ok then
		errorNHf("AIBases.PropBrick:Spawn() : missing value `%s`.", miss or "?")
		return
	end

	if data.class == "prop_dynamic" then data.class = "prop_physics" end

	local ent = ents.Create(data.class)
	self.Ent = ent

	-- timer.Simple(5, function() ent:Remove() end)

	ent:SetModel(data.model)
	ent:SetPos(data.pos)
	ent:SetAngles(data.ang)
	ent:SetModelScale(data.scale)
	ent.Brick = self

	ent:Spawn()
	ent:Activate()

	if data.skin ~= 0 then
		ent:SetSkin(data.skin)
	end

	if data.bgs ~= "" then
		ent:SetBodyGroups(data.bgs)
	end


	if data.freeze then
		local pobj = ent:GetPhysicsObject()
		if IsValid(pobj) then
			pobj:EnableMotion(false)
		end
	end
end

function AIBases.PropBrick:Remove()
	if IsValid(self.Ent) then self.Ent:Remove() end
end

function AIBases.PropBrick:Build(ent)
	local new = AIBases.PropBrick:new()
	local data = new.Data

	data.model = ent:GetModel()
	data.pos = ent:GetPos()
	data.ang = ent:GetAngles()

	local sc = ent:GetModelScale()
	if sc ~= 1 then data.scale = sc end

	local class = ent:GetClass()
	if class ~= "prop_physics" then data.class = class end

	if ent:GetSkin() ~= 0 then
		data.skin = ent:GetSkin()
	end

	local bgStr = ent:GetBodygroupsSet()
	if bgStr:match("[^0]") then
		data.bgs = bgStr
	end

	return new
end

AIBases.PropBrick:Register()