local PLAYER = debug.getregistry().Player

BaseWars.AFK = BaseWars.AFK or {}
local AFK = BaseWars.AFK

AFK.CLEAR = 0
AFK.FOCUS = 1

function AFK.IsAFK(ply)
	return ply:GetNW2Bool("IsAFK", false)
end
PLAYER.IsAFK = AFK.IsAFK

function AFK.AFKTime(ply)
	return ply:IsAFK() and CurTime() - ply:GetNW2Float("AFK") or 0
end

PLAYER.AFKTime = AFK.AFKTime

local clear = function(ply)
	if CLIENT then
		AFK.ClearAFK()
	else
		AFK.ActionPerformed(ply)
	end
end

hook.Add("PlayerSay", "AFKClear", clear)
hook.Add("KeyPress", "AFKClear", clear)

if CLIENT then
	local ox, oy, oa

	local cmdclear = function(cmd)
		local ply = LocalPlayer()

		if ply:IsAFK() and cmd:GetMouseX() ~= ox or cmd:GetMouseY() ~= oy then
			clear()
			ox, oy = cmd:GetMouseX(), cmd:GetMouseY()
		end
	end

	hook.Add("PlayerBindPress", "AFKClear", clear)
	hook.Add("CreateMove", "AFKClear", cmdclear)
	-- hook.Add("Tick", "AFKClear", tickclear)
	hook.Add("StartChat", "AFKClear", clear)
	hook.Add("VGUIMousePressed", "AFKClear", clear)

	local reported = true

	timer.Create(":crab:YOU____ARE GONE:crab:", 1, 0, function()
		if reported ~= system.HasFocus() then
			AFK.SendFocus(system.HasFocus())
			reported = system.HasFocus()
		end
	end)

end
