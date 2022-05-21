net.Receive("aib_layout", function(len, ply)
	if not bld.Allowed(ply) then return end

	local mode = net.ReadUInt(4)

	if mode == 0 then
		-- mark
		local ent = net.ReadEntity()
		local how = net.ReadUInt(4)

		if how == 15 then
			how = nil
		else
			if ent.IsAIBaseBot 		then how = AIBases.BRICK_ENEMY 	end
			if ent.IsAIWall 		then how = AIBases.BRICK_BOX 	end
			if ent.IsMorphDoor 		then how = AIBases.BRICK_DOOR 	end
			if ent.IsAIBaseSignal 	then how = AIBases.BRICK_SIGNAL end
			if ent.IsLootableBoks 	then how = AIBases.BRICK_LOOT 	end
		end

		AIBases.Builder.AddBrick(ply, ent, how)
	elseif mode == 1 then
		local where = net.ReadVector()

		local en = ents.Create("aib_bot")

		en.NoTarget = net.ReadBool()
		local wepClass = net.ReadString()
		local tier = net.ReadUInt(8)

		en:SetPos(where)
		en.ForceWeapon = wepClass
		en.Tier = tier

		local ang = (ply:EyePos() - where):Angle()
		ang.p = 0
		en:SetAngles(ang)

		en:Spawn()
		en:Activate()

		undo.Create("ai bot")
			undo.SetPlayer(ply)
			undo.AddEntity(en)
		undo.Finish("ai bot")

		en.debug = true
		_G.bot = en
	elseif mode == 2 then
		local where = net.ReadVector()
		local mdl = net.ReadString()
		local pool = net.ReadString()

		local en = ents.Create("lootable")
		en:SetPos(where)
		en:SetModel(mdl)
		en:SetLootPool(pool)
		en:Spawn()

		undo.Create("Lootable: " .. pool)
			undo.SetPlayer(ply)
			undo.AddEntity(en)
		undo.Finish("Lootable: " .. pool)
	end
end)