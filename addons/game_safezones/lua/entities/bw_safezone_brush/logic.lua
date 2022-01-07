Safezones.Tracker = Safezones.Tracker or {}
local trk = Safezones.Tracker

Safezones.RemTracker = Safezones.RemTracker or {}
local rtrk = Safezones.RemTracker

function Safezones.StartTouch(brush, ent)
	local first = not trk[ent]
	trk[ent] = brush

	if first and ent:IsPlayer() then
		ent:SetNWFloat("Safezone", CurTime())
	end

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
	if trk[ent] ~= brush then return end
	trk[ent] = nil
	rtrk[ent] = nil

	if ent:IsPlayer() then
		ent:SetNWFloat("Safezone", 0)
	end
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