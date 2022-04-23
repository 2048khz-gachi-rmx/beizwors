Safezones.Tracker = Safezones.Tracker or muldim:new()
local trk = Safezones.Tracker

Safezones.RemTracker = Safezones.RemTracker or {}
local rtrk = Safezones.RemTracker

Safezones.Data = Safezones.Data or muldim:new()
local data = Safezones.Data
data.Linger = data.Linger or muldim:new()

function Safezones.StartTouch(brush, ent)
	local t = trk:GetOrSet(ent)
	local dat = data:GetOrSet(ent)

	local first = table.IsEmpty(t)
	t[brush] = true

	if first then
		dat.enterTime = CurTime()
		dat.firstBrush = brush -- ?
		dat.exitTime = nil
	end

	hook.Run("SafezoneEntered", first, ent, brush, dat)

	if first and IsValid(ent:CPPIGetOwner()) then
		if ent.IsBaseWars then
			ent:CPPIGetOwner():ChatPrint("Remove your " .. (ent.PrintName or ent:GetClass()) .. " from spawn or it will be removed!")
			rtrk[ent] = CurTime()
		elseif ent:GetClass() == "prop_physics" then
			SafeRemoveEntityDelayed(ent, 0)
			ent:CPPIGetOwner():ChatPrint("Props in safezones aren't allowed.")
		end
	end
end

function Safezones.EndTouch(brush, ent)
	local t = trk:GetOrSet(ent)
	local dat = data:GetOrSet(ent)

	local last = next(t) == brush and not next(t, brush)

	hook.Run("SafezoneOnExit", last, ent, brush)

	t[brush] = nil
	rtrk[ent] = nil

	hook.Run("SafezoneExited", last, ent, brush)
	if not last then return end

	dat.exitTime = CurTime()
	dat.enterTime = nil
	dat.firstBrush = nil
end

function Safezones.Touch(brush, ent)
	if rtrk[ent] and CurTime() - rtrk[ent] >= 5 then
		ent:Remove()
		if IsValid(ent:CPPIGetOwner()) then
			ent:CPPIGetOwner():ChatPrint("Your " .. (ent.PrintName or ent:GetClass()) ..
				" was destroyed because it was in a safezone for too long!")
			rtrk[ent] = nil
			trk[ent] = nil
		end
	end
end

hook.Add("SafezoneEntered", "GiveInvuln", function(first, ent)

	if first and IsPlayer(ent) then
		ent:SetNWFloat("Safezone", CurTime())
		ent:SetNWBool("InSafezone", true)
	end

end)

hook.Add("SafezoneOnExit", "LingerTrack", function(last, ent)
	if not last or not IsPlayer(ent) then return end

	if Safezones.IsProtected(ent, true) and Safezones.ShouldLinger(ent) then
		Safezones.AddLinger(ent)
	end
end)

hook.Add("SafezoneExited", "GiveInvuln", function(last, ent)

	if last and IsPlayer(ent) then
		ent:SetNWFloat("Safezone", CurTime())
		ent:SetNWBool("InSafezone", false)
	end
end)

function Safezones.IsIn(ent)
	return next(trk:GetOrSet(ent)) ~= nil
end

function Safezones.TimeSinceIn(ent)
	local t = data:GetOrSet(ent)
	return CurTime() - (t.enterTime or 0), t.enterTime
end

function Safezones.TimeSinceOut(ent)
	local t = data:GetOrSet(ent)
	return CurTime() - (t.exitTime or 0), t.exitTime
end

function Safezones.IsProtecting(ent)
	-- returns whether the entity is in the process of being protected
	local t = data:GetOrSet(ent)

	--[[if t.lastDmg then
		local since = CurTime() - t.lastDmg
		if since < 3 then return false end
	end]]

	if not Safezones.IsIn(ent) then return false end

	return CurTime() - Safezones.TimeSinceIn(ent) < Safezones.TimeTillProtection
end

function Safezones.AddLinger(ply, t)
	t = t or CurTime()
	data.Linger[ply] = math.max(t, data.Linger[ply] or 0)

	local dat = data:GetOrSet(ply)
	dat.exitWithProt = math.max(t, dat.exitWithProt or 0)

	ply:SetNWFloat("LingerStart", t)
end

function Safezones.ResetLinger(ply)
	local t = data:GetOrSet(ply)
	t.exitWithProt = nil

	ply:SetNWFloat("LingerStart", 0)
	data.Linger[ply] = nil
end

function Safezones.IsLingering(ent)
	local t = data.Linger[ent]
	if not t then return false end

	if not Safezones.ShouldLinger(ent) then
		Safezones.ResetLinger(ent)
		return false
	end

	if CurTime() - t > Safezones.ProtectionLinger then
		Safezones.ResetLinger(ent)
		return false
	end

	return true
end

local whitelist = {
	weapon_physgun = true,
	weapon_physcannon = true,
	hands = true,
	gmod_camera = true,
	gmod_tool = true,
}

function Safezones.ShouldLinger(ply)
	local wep = ply:GetActiveWeapon()
	if IsValid(wep) and not whitelist[wep:GetClass()] then return false end
	if ply:InRaid() then return false end

	return true
end

timer.Create("SafezoneLinger", 0.25, 0, function()
	for k,v in pairs(data.Linger) do
		if not k:IsValid() then data.Linger[k] = nil continue end
		if not Safezones.ShouldLinger(k) then
			Safezones.ResetLinger(k)
		end
	end
end)

hook.Add("PlayerShouldTakeDamage", "Safezones", function(vic, atk)
	if not IsValid(vic) then return end

	local vicIn, atkIn = Safezones.IsIn(vic), Safezones.IsIn(atk)
	if atkIn and vicIn then return false end -- cant attack if both are in safezone

	if Safezones.IsProtected(atk, true) then return false end -- protected cant attack
	if Safezones.IsProtected(vic) then return false end -- cant attack protected (w/ linger)
end)

hook.Add("PostEntityTakeDamage", "Safezones", function(ent, dmg, took)
	if not took or dmg:GetDamage() == 0 then return end

	data:GetOrSet(ent).lastDmg = CurTime()

	local atk = dmg:GetAttacker()

	if IsPlayer(atk) then
		Safezones.ResetLinger(atk)
	end
end)

hook.Add("PlayerSpawnObject", "Safezones", function(ply)
	Safezones.ResetLinger(ply)
end)

hook.Add("PlayerSpawnedProp", "Safezones", function(ply)
	Safezones.ResetLinger(ply)
end)

hook.Add("ArcCW_GunDeployed", "Safezones", function(wep, ply)
	Safezones.ResetLinger(ply)
end)