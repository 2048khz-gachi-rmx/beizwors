local function stim(ply)
	return Stims.Active[ply]
end

function Stims.UseStim()
	local ply = LocalPlayer()
	if not ply:Alive() or ply:Health() >= ply:GetMaxHealth() then return end
	if hook.Run("CanUseStimpak", ply) == false then return end

	local dat = stim(ply)

	if dat then

		if not dat.Deinjecting then
			-- forcefully end stimpack
			dat.Working = false
			dat.Deinjecting = CurTime()

			VManip.SegmentFinished = true --fuck you
			VManip:PlaySegment("stim_inject_end", true)

			net.Start("ProcStim")
			net.SendToServer()
		end

		return
	end

	local can = VManip:PlayAnim("stim_inject_start")
	if not can then return end -- trust the client, YEET

	VManip._PlayedStim = false

	net.Start("ProcStim")
	net.SendToServer()

	Stims.AddStim(ply)

	ply:EmitSound(Stims.Sound("adrenaline_deploy_1"), 75)
	ply:Timer("stim_cap_off", 0, 1, ply.EmitSound,
		Stims.Sound("needle_open"), 80)
end


hook.Add("Offhand_GenerateSelection", "ShowStim", function(bind, wheel)
	local stim = Offhand.AddChoice(Stims.ActionName,
		"Stimpack", "Heal 75HP over 1.5s.",
		Icon("https://i.imgur.com/1aEZv3d.png", "adrenaline_shot128.png"):
			SetSize(64, 64))

	stim:On("Select", function()
		Offhand.SetBindAction(bind, Stims.ActionName)
	end)
end)

hook.Add("Offhand_GenerateSelection", "ShowNothing", function(bind, wheel)
	local stim = Offhand.AddChoice("fucking nothing",
		"nothing", "lole",
		Icon("https://i.imgur.com/6se0gFC.png", "none64_gray.png"):
			SetSize(64, 64))

	stim:On("Select", function()
		Offhand.SetBindAction(bind, "fucking nothing")
	end)
end)

hook.Add("VManipPlaySegment", "Stims", function()
	if VManip:GetCurrentSegment() == "stim_inject_end" then
		ply:EmitSound(Stims.Sound("thud_01"), 50, 170, 0.3)
	end
end)

hook.Add("VManipThink", "Stims", function()
	local cur = VManip:GetCurrentSegment() or VManip:GetCurrentAnim()

	if cur == "stim_inject_start" then
		local cyc = VManip.Cycle
		if cyc > 0.6 and not VManip._PlayedStim then
			VManip._PlayedStim = true
			ply:EmitSound(Stims.Sound("thud_01"), 75)
		end
	end
end)

local function stimDeinject()
	if not CLIENT then return end

	local dat = stim(LocalPlayer())
	VManip.SegmentFinished = true --fuck you
	VManip:PlaySegment("stim_inject_end", true)

	dat.Working = false
	dat.Deinjecting = CurTime()

end

gameevent.Listen("entity_killed")

hook.Add("entity_killed", "StimpakTrack", function(t)
	local victim = Entity(t.entindex_killed)
	if victim ~= LocalPlayer() then return end

	Stims.RemoveStim( victim )
end)

hook.Add("Think", "Stimpak", function()
	local lp = LocalPlayer()
	local t = stim(lp)

	if not t then return end

	if not t.Working then

		if not t.Deinjecting and CurTime() - t.Started > t.WorkTime then
			-- not deinjecting and it's time to start working
			t.Working = true
			t.WorkingTime = CurTime()
		elseif t.Deinjecting and CurTime() - t.Deinjecting > t.DeinjectTime then
			-- deinjecting and it's time to stop completely
			Stims.RemoveStim( lp )
			return
		end

	elseif CurTime() - t.WorkingTime > t.HealTime or lp:Health() >= lp:GetMaxHealth() then
		-- was working and it's time to stop (max hp reached or all heals spent)
		stimDeinject()
	end

end)