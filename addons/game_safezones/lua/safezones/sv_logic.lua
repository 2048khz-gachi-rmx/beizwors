Safezones.Tracker = Safezones.Tracker or muldim:new()
local trk = Safezones.Tracker

Safezones.RemTracker = Safezones.RemTracker or {}
local rtrk = Safezones.RemTracker

Safezones.Data = Safezones.Data or muldim:new()
local data = Safezones.Data

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

	t[brush] = nil
	rtrk[ent] = nil
	local last = table.IsEmpty(t)

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

hook.Add("SafezoneExited", "GiveInvuln", function(last, ent)

	if last and IsPlayer(ent) then
		ent:SetNWFloat("Safezone", CurTime())
		ent:SetNWBool("InSafezone", false)

		local t = data:GetOrSet(ent)

		if Safezones.IsProtected(ent, true) then
			t.exitWithProt = CurTime()
		end
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

Safezones.TimeTillProtection = 5
Safezones.ProtectionLinger = 30

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

function Safezones.IsProtected(ent, nolinger)
	-- returns whether the entity is already protected

	if not nolinger and not Safezones.IsIn(ent) then
		-- ?
		return false
	end

	return Safezones.TimeSinceIn(ent) > Safezones.TimeTillProtection
end

hook.Add("PlayerShouldTakeDamage", "Safezones", function( ply, atk )
	if not IsValid(ply) then return end

	local vicIn, atkIn = Safezones.IsIn(ply), Safezones.IsIn(atk)
	if atkIn and vicIn then return false end

	if ply:GetNWFloat("Safezone", 0) ~= 0 and ply:GetNWFloat("Safezone", 0) < CurTime() - 5 then return false end
	if atk:GetNWFloat("Safezone", 0) > 0 then return false end
end)

hook.Add("PostEntityTakeDamage", "Safezones", function(ent, dmg, took)
	if not took or dmg:GetDamage() == 0 then return end

	data:GetOrSet(ent).lastDmg = CurTime()
end)