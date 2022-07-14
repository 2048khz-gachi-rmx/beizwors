--

function AIBases.ConstructNavs(navs)
	local cnavs = navmesh.GetAllNavAreas()
	local lkup = {}
	local llkup = {}
	for k,v in pairs(cnavs) do lkup[v:GetID()] = v end
	for k,v in pairs(navs) do llkup[v.uid] = v end

	for k, lnav in pairs(navs) do
		lnav:Spawn(lkup)
	end

	for k, lnav in pairs(navs) do
		lnav:PostSpawn(lkup, llkup)
	end
end


function AIBases.SelectLayout(base)
	local dat = base:GetData()
	local pool = dat.AILayouts

	if not pool then
		return false
	end


	local sel, seltier

	for tier, lays in RandomPairs(pool) do
		if #lays == 0 then continue end
		sel = table.Random(lays)
		seltier = tier
	end

	base.SelectedLayout = sel
	base.RequiredTier = seltier

	return sel, seltier
end

function AIBases.BaseRequireTier(base, t)
	local sigs = base.EntranceLayout:GetBricksOfType(AIBases.BRICK_SIGNAL)
	if not sigs then
		errorNHf("base `%s` has no signals; not requiring tier", base:GetName())
		return
	end

	for k,v in pairs(sigs) do
		if v.SetTier then v:SetTier(t) end
	end
end

function AIBases.GetBaseType(base, entr)
	local dbricks = entr:GetBricksOfType(AIBases.BRICK_SIGNAL)

	-- no signal bricks, probably free entrance
	if not dbricks then
		return AIBases.BaseTypes.FREE
	end

	for k,v in pairs(dbricks) do
		-- entrance has a keyreader; probably keycard entrance
		if IsValid(v.Ent) and v.Ent.IsAIKeyReader then
			return AIBases.BaseTypes.KEYCARD
		end
	end

	return AIBases.BaseTypes.FREE
end

function AIBases.HookGeneration(base, entr)
	local typ = AIBases.GetBaseType(base, entr)

	if not typ then
		errorNHf("Failed to recognize base type: %s", base)
		return
	end

	if not isfunction(AIBases.Regeneration[typ]) then
		errorNHf("No regeneration method for typ %s", typ)
		return
	end

	AIBases.Regeneration[typ] (base, entr)
end

function AIBases.SpawnBase(base)
	if base.ActiveLayout then
		errorNHf("Attempted to create multiple layouts for base? %s", base)
		return
	end

	local dat = base:GetData()
	local entranceName = dat.AIEntrance

	base.EntranceLayout = AIBases.BaseLayout:new(entranceName)
	local ok = base.EntranceLayout:ReadFrom(entranceName, true)
	if not ok then
		errorNHf("failed to read entrance layout with the name `%s`.", entranceName)
		return
	end

	ok:Spawn()

	AIBases.HookGeneration(base, ok)
end

function AIBases.DespawnBase(base, layout)
	-- close the entrances
	local dbricks = base.EntranceLayout:GetBricksOfType(AIBases.BRICK_SIGNAL)
	if dbricks then
		for k,v in pairs(dbricks) do
			if not IsValid(v.Ent) or not v.Ent.IsAIKeyReader then
				errorNHf("brick %s has invalid ent!? %s", v, v.Ent)
				continue
			end

			v.Ent:Close()
		end
	end

	-- despawn the actual layout
	layout:Despawn()
	base.ActiveLayout = nil
end

hook.Add("PreCleanupMap", "DespawnLayouts", function()
	for k,v in pairs(BaseWars.Bases.Bases) do
		if v.ActiveLayout then
			AIBases.DespawnBase(v, v.ActiveLayout)
		end

		if v.EntranceLayout then
			AIBases.DespawnBase(v, v.EntranceLayout)
		end

		v:Emit("Cleanup")
	end
end)