--
local PIN = LibItUp.PlayerInfo

hook.Add("NetworkableVarChanged", "TrackResearch", function(nw, key, old, new)
	local pin = nw.IsPrivateNW
	if not pin or pin:GetPlayer() ~= CachedLocalPlayer() then
		return
	end

	if not key:match("^rs_") then return end

	key = key:gsub("^rs_", "")

	local rs = pin:GetResearchedPerks()
	rs[key] = new
end)

function PIN:GetResearchedPerks()
	self._perks = self._perks or {}
	return self._perks
end

PInfoAccessor("ResearchedPerks")