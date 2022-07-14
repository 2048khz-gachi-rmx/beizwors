local bwbase = BaseWars.Bases.Base

function bwbase:MakeAI(entr, layouts)
	if entr == nil and self:GetData().AIEntrance == nil then
		errorf("`bwbase:MakeAI(entrance_name, layouts)`: missing entrance name. Give `false` to not have any.")
		return
	elseif entr then
		assertf(isstring(entr), "Entrance must be a string.")
	end

	if layouts == nil and entr ~= false and self:GetData().AILayouts == nil then
		errorf("`bwbase:MakeAI(entrance_name, layouts)`: missing layouts. Either give no entrance or give false.")
		return
	elseif layouts then
		assertf(istable(layouts), "Entrance must be a table.")
		assertf(layouts[1] and layouts[2] and layouts[3], "Incorrect layouts table layout.")
	end

	self:AddData("AIBase", true, true)

	if entr ~= false then
		self:AddData("AIEntrance", entr, true)
		self:AddData("AILayouts", layouts, true)
	end

	self:SaveData()
end

function bwbase:AI_ShouldEntTakeDamage(ent, atk, dmg)
	if ent.Brick and ent.Brick.type == AIBases.BRICK_PROP then
		return ent.Brick.Breakable -- prop brick ent
	end

	if ent.PermaProps then
		local dat = ent.PersistentData

		if dat and dat.BaseBreakable then
			dmg:ScaleDamage(0.5)
			print("aibase says take")
			return true
		end

		-- permaprops in AI bases dont take dmg unless explicitly set to
		return false
	end

	return true
end