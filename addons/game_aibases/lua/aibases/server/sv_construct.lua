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


function AIBases.ConstructLayout(lay)
	for k,v in pairs(lay.Bricks) do
		v:Spawn()
	end


end

function AIBases.ConstructBase(base)
	local lay = base:GetLayout()
end

local guns = {
	"cw_acr",
	"cw_mp5",
	"cw_ump45",
	"cw_mp9_official",
	"cw_mac11",
	"cw_mp7_official",
}

function AIBases.ConstructEnemies(spots)
	--[[local out = {}

	for k,v in pairs(spots) do
		local en = ents.Create("aib_bot")
		out[en] = true

		en:Give(table.Random(guns))
		en:SetPos(v)
		en:Spawn()
		en:Activate()
	end

	return out]]
end

function AIBases.SelectLayout(base)
	local dat = base:GetData()
	local pool = dat.AILayouts

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

function AIBases.SpawnBase(base)
	local dat = base:GetData()
	local entranceName = dat.AIEntrance
	local pool = dat.AILayouts

	if not pool then
		errorNHf("no layouts pool for base %s", base:GetName())
		return
	end

	base.EntranceLayout = AIBases.BaseLayout:new()
	local ok = base.EntranceLayout:ReadFrom(entranceName)
	if not ok then
		errorNHf("failed to read entrance layout with the name `%s`.", entranceName)
		return
	end

	ok:Spawn()

	local layName, layTier = AIBases.SelectLayout(base)
	AIBases.BaseRequireTier(base, layTier)

	local dbricks = ok:GetBricksOfType(AIBases.BRICK_SIGNAL)
	if not dbricks then
		errorNHf("entrance layout `%s` has no keyreaders; not hooking generation", entranceName)
		return
	end

	base.ActiveLayout = nil

	local genned

	for k,v in pairs(dbricks) do
		if not IsValid(v.Ent) or not v.Ent.IsAIKeyReader then
			errorNHf("brick %s has invalid ent!? %s", v, v.Ent)
			return
		end

		v.Ent:On("StartUsingValidCard", "GenerateOnOpen", function()
			if genned then return end -- already generated

			genned = true

			base.ActiveLayout = AIBases.BaseLayout:new(layName)
			base.ActiveLayout:ReadFrom(layName)
			base.ActiveLayout:SlowSpawn(1)
			base.ActiveLayout:BindToBase(base)

			base.ActiveLayout:On("Despawn", "Base", function()
				base.ActiveLayout = nil
				genned = false
			end)
		end)
	end
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