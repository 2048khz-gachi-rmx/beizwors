print("sv stims included")

local function stim(ply)
	return Stims.Active[ply]
end

util.AddNetworkString("ProcStim")

local function reply(pr, b)
	pr:ReplySend("ProcStim", false)
end

net.Receive("ProcStim", function(_, ply)
	local pr = net.ReplyPromise(ply)

	if not ply:Alive() then reply(pr, false) return end

	if ply:Health() >= ply:GetMaxHealth() and
		hook.Run("CanForceStimpak", ply) ~= true then
		reply(pr, false)
		return
	end

	if hook.Run("CanUseStimpak", ply) == false then
		reply(pr, false)
		return
	end
	
	print("AEEEE done")
	local dat = stim(ply)

	if dat then

		if not dat.Deinjecting then
			-- forcefully end stimpack
			dat.Working = false
			dat.Deinjecting = CurTime()
		end

		return
	end

	Stims.AddStim(ply)
end)

--Stims.Bind:On("Activate", "BeginStim", function(self, ply)

--end)


hook.Add("PlayerDeath", "StimpakTrack", function(ply)
	Stims.RemoveStim(ply)
end)

hook.Add("Think", "Stimpak", function()
	local ct = CurTime()

	for ply, t in pairs(Stims.Active) do
		if not ply:IsValid() then Stims.RemoveStim(ply) continue end

		if not t.Working and not t.Deinjecting and ct - t.Started > t.WorkTime then
			-- stim started working
			t.Working = true
			t.HealStart = t.Started + t.WorkTime
			t.HealLeft = t.Heal
			t.HealSpent = 0

			hook.Run("PlayerStimInjected", ply, t)
		end

		if t.Working then

			if t.HealLeft > 0 and ply:Health() < ply:GetMaxHealth() and ply:Alive() then
				local should_heal = math.floor(math.min((CurTime() - t.HealStart) / t.HealTime, 1) * t.Heal)
				local toheal = should_heal - t.HealSpent
				if toheal < 1 then continue end

				toheal = math.min(toheal, t.Heal)
				ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + toheal))

				t.HealLeft = t.Heal - should_heal
				t.HealSpent = should_heal
			else
				t.Working = false
				t.Deinjecting = ct
			end

		elseif t.Deinjecting then
			if CurTime() - t.Deinjecting > STIMPAK_REMOVE_TIME then
				Stims.RemoveStim(ply)
			end
		end
	end
end)