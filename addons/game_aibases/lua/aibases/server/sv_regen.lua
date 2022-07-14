AIBases.Regeneration = AIBases.Regeneration or {}

local regen = AIBases.Regeneration

regen[AIBases.BaseTypes.FREE] = function(base, entr)
	local pr = entr:InteractionTimer(base, 45, 300)
	local ename = "Regen:" .. entr.Name
	local done = false

	local cleanup = Once(function()
		base:RemoveListener("EntityEntered", ename)
		base:RemoveListener("EntityExited", ename)
		done = true
	end)

	local spawn = Once(AIBases.SpawnBase)

	local function startRegen()
		if base:TimerExists(ename) or done then return end

		local time = math.Rand(15, 40)
		printf("Started regen timer (in %.1f)", time)

		base:Timer(ename, time, 1, function()
			if done then return end
			cleanup()
			spawn(base)
			print("Regen complete!!!")
		end)
	end

	local function stopRegen()
		if done then error("Bad state") return end
		print("Stopped regen timer.")
		base:RemoveTimer(ename)
	end

	-- free bases don't really do anything special on timeout;
	-- just launch our own respawn behavior and chill
	pr:Then(function(_, why)
		printf("Base despawn due to %s", why)
		AIBases.DespawnBase(base, entr)

		base:On("EntityEntered", ename, function(_, ent)
			if done then error("Bad state") return end -- debug
			if ent:IsPlayer() then
				stopRegen()
			end
		end)

		base:On("EntityExited", ename, function(_, ent)
			if done then error("Bad state") return end -- debug
			if ent:IsPlayer() and #base:GetPlayers() == 0 then
				startRegen()
			end
		end)

		if #base:GetPlayers() == 0 then
			startRegen()
		end

		-- force regen if they camp the looted base or something
		base:Timer("Forced" .. ename, math.Rand(260, 400), 1, function()
			print("Forcing cleanup")
			stopRegen()
			spawn(base)
		end)
	end)
end


regen[AIBases.BaseTypes.KEYCARD] = function(base, entr)
	-- what layout will we generate once the keyreader opens up?
	local layName, layTier = AIBases.SelectLayout(base)
	if layName then
		AIBases.BaseRequireTier(base, layTier)
	end

	local dbricks = entr:GetBricksOfType(AIBases.BRICK_SIGNAL)
	if not dbricks then
		printf("entrance layout `%s` has no keyreaders; not hooking generation", entranceName)
		return
	end

	base.ActiveLayout = nil

	local genned

	for k,v in pairs(dbricks) do
		if not IsValid(v.Ent) then
			errorNHf("brick %s has invalid ent!? %s", v, v.Ent)
			continue
		end

		if not v.Ent.IsAIKeyReader then continue end

		-- hook keyreader to generate the entrance once activated
		v.Ent:On("StartUsingValidCard", "GenerateOnOpen", function()
			if genned then return end
			genned = true

			base.ActiveLayout = AIBases.BaseLayout:new(layName)
			base.ActiveLayout:ReadFrom(layName)
			base.ActiveLayout:SlowSpawn(1)
			local miss = base.ActiveLayout:InteractionTimer(base, 30, 600, true)

			miss:Then(function(_, why)
				printf("Base despawn due to %s", why)
				AIBases.DespawnBase(base, base.ActiveLayout)
			end)

			base.ActiveLayout:On("Despawn", "Base", function()
				base.ActiveLayout = nil
				genned = false
			end)
		end)
	end
end

local layout = AIBases.BaseLayout

function layout:InteractionTimer(base, interactTimeout, hardTimeout, immediateInteract)
	CheckArg(2, interactTimeout, isnumber)

	local interacted = false
	local first, last = CurTime(), CurTime()

	local emptyTime = 0 -- how much time during regen countdown we spent without anyone in the base
	local prom = Promise()

	local function finish(...)
		self:RemoveTimer("AIB_TrackInteract")
		prom:Resolve(...)
	end

	local function createTimer()
		if immediateInteract or self:TimerExists("AIB_TrackInteract") then return end

		self:Timer("AIB_TrackInteract", 1, "0", function()
			if CurTime() - last > interactTimeout then
				-- some time passed since last interaction... is there anyone left?
				prom:Emit("InteractTimeout")
				if table.IsEmpty(base:GetPlayers()) then
					-- some time passed since last interaction and noone is in
					emptyTime = emptyTime + 1
					prom:Emit("EmptyTick")
				else
					-- someone's inside...?
					emptyTime = 0
					prom:Emit("FullReset")
				end

				if emptyTime >= 15 then
					-- noone inside for quite some time now; die due to no interactions
					finish("nointeract")
					return
				end
			end

			if hardTimeout and CurTime() - first > hardTimeout then
				-- hard timeout reached
				finish("timeout")
			end
		end)
	end

	local function interact()
		if not interacted then
			interacted = true
			first = CurTime()
			createTimer()
		end

		last = CurTime()
	end

	if immediateInteract then
		interact()
	end

	local enemies = self:GetBricksOfType(AIBases.BRICK_ENEMY)

	for k,v in pairs(enemies) do
		if not IsValid(v.Ent) then
			errorNHf("brick %s has invalid ent!? %s", v, v.Ent)
			continue
		end

		local bot = v.Ent
		bot:On("EnemyFound", "TrackInteract", interact)
		bot:On("OnTakeDamage", "TrackInteract", interact)
	end

	return prom
end