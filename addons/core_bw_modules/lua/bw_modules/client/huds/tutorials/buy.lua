--
local tut = BaseWars.Tutorial
local ptr = tut.AddStep(4, "Automation")

ptr.SolarPanels = {}

function ptr:PaintAuto(cury)
	local mask = 0
	local tracking, complete

	-- prioritize a panel with both accesses,
	-- then with sun access, and base access as last priority

	for ent,v in pairs(self.SolarPanels) do
		if not ent:IsValid() then self.SolarPanels[ent] = nil continue end

		local haveSun = ent:GetSunAccess()
		local haveBase = ent:GetBaseAccess()

		local condMask = bit.lshift(tobit(haveSun), 1) + tobit(haveBase)
		mask = math.max(mask, condMask)
	end

	ptr:CompletePoint(2, bit.Has(mask, 2)) -- sun
	ptr:CompletePoint(3, bit.Has(mask, 1)) -- base

	return self:PaintPoints(cury)
end

ptr:AddPaint(999, "PaintFrame", ptr)
ptr:AddPaint(998, "PaintName", ptr)
ptr:AddPaint(997, "PaintAuto", ptr)

ptr:AddPoint(1, "Purchase a solar panel.")
ptr:AddPoint(2, "Provide sky access to your solar panel.")
ptr:AddPoint(3, "Make sure the panel provides power for your base.")

local function tryTrack(ent)
	if ent.IsSolarPanel and ent:BW_IsOwner(LocalPlayer()) then
		ptr:CompletePoint(1, true)
		ptr.SolarPanels[ent] = true
	end
end

ptr:On("Appear", "TryTrack", function()
	for k,ent in ipairs(ents.FindByClass("*bw_*")) do
		tryTrack(ent)
	end
	print("LE SOLAR HAS APPEARED")
	BaseWars.SpawnMenu.Highlight["bw_gen_solar"] = true
end)

ptr:On("Completed", "RemoveHilite", function()
	BaseWars.SpawnMenu.Highlight["bw_gen_solar"] = nil
end)

hook.Add("EntityOwnershipChanged", "TrackAutomationTutorial", function(ply, ent)
	if ply ~= LocalPlayer() then return end
	tryTrack(ent)
end)