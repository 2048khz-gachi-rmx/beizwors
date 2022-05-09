local sig = AIBases.LayoutBrick

AIBases.SignalBrick = AIBases.SignalBrick or sig:callable()
AIBases.SignalBrick.DataClass = sig.DataClass:callable({
	class = TYPE_STRING,
	pos = TYPE_VECTOR,
	ang = {TYPE_ANGLE, default = angle_zero},
	model = {TYPE_STRING, default = ""},
	con = {TYPE_TABLE, default = {}},
	freeze = {TYPE_BOOL, default = true},
})

AIBases.SignalBrick.type = AIBases.BRICK_SIGNAL

function AIBases.SignalBrick:Build(ent)
	local new = AIBases.SignalBrick:new()

	local pos = ent:GetPos()
	local ang = ent:GetAngles()

	new.Data.pos = pos
	new.Data.ang = ang
	new.Data.class = ent:GetClass()
	if ent.ModelOverride then new.Data.model = ent.ModelOverride end
	new.outs = ent.Outputs

	if new.Data.ang == angle_zero then new.ang = nil end

	return new
end

function AIBases.SignalBrick:PostBuild(others)
	local outs = self.outs
	local ser = {}

	local lkup = {}
	-- [ent] = brick
	for k,v in pairs(others) do lkup[v.BuiltFrom] = v end

	for outName, dat in pairs(outs) do
		local to = dat.Connected
		local t = {}
		ser[outName] = t

		for _, con in pairs(to) do
			local brick = lkup[con.Entity]
			if not brick then
				errorNHf("failed to find brick for connected entity %s -> %s", self, con.Entity)
				continue
			end

			local uid = brick.Data.uid
			t[uid] = con.Name
		end
	end

	self.Data.con = ser
end

function AIBases.SignalBrick:Remove()
	if IsValid(self.Ent) then self.Ent:Remove() end
end

function AIBases.SignalBrick:Spawn()
	if IsValid(self.Ent) then self.Ent:Remove() end

	local data = self.Data

	local ent = ents.Create(data.class)
	self.Ent = ent

	-- timer.Simple(5, function() ent:Remove() end)

	ent:SetModel(data.model)
	ent:SetPos(data.pos)
	ent:SetAngles(data.ang)
	if data.model ~= "" then ent:SetModel(data.model) end

	ent.Brick = self

	ent:Spawn()
	ent:Activate()

	if data.freeze then
		local pobj = ent:GetPhysicsObject()
		if IsValid(pobj) then
			pobj:EnableMotion(false)
		end
	end
end

function AIBases.SignalBrick:PostSpawn(lay)
	local con = self.Data.con
	-- WireLib.Link_Start(0, ent, input.StartPos, k, input.Material, input.Color, input.Width)

	for out, dat in pairs(con) do
		for uid, inp in pairs(dat) do
			local bk = lay:GetBrick(uid)
			WireLib.Link_Start(0, bk.Ent, bk.Ent:GetPos(), inp, "", color_trans, 0)
			WireLib.Link_End(0, self.Ent, self.Ent:GetPos(), out, NULL)

			printf("connecting %s -> [%s]%s", out, uid, inp)
		end
	end

	WireLib.Link_Start(0, this, there, "Open", "", color_trans, 0)

end

AIBases.SignalBrick:Register()