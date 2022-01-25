--

local PLAYER = FindMetaTable("Player")

function PLAYER:GetResearchedPerks()
	self._perks = self._perks or {}
	return self._perks
end

function PLAYER:Research(lv)
	assert(Research.IsPerkLevel(lv))

	local perk = lv:GetPerk():GetID()
	assert(perk, "no perk?")

	self:GetResearchedPerks()[perk] = lv:GetLevel()
	hook.Run("PlayerResearched", self, lv:GetPerk(), lv:GetLevel())
end