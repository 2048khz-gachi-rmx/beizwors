--

local PLAYER = FindMetaTable("Player")
local PIN = LibItUp.PlayerInfo

function PIN:GetPerkLevelNumber(nm)
	if Research.IsPerk(nm) then nm = nm:GetID() end
	return self:GetResearchedPerks()[nm] or 0
end

function PIN:GetPerkLevel(nm)
	local perk
	if Research.IsPerk(nm) then
		perk = nm
	else
		perk = Research.GetPerk(nm)
	end

	if not perk then return false end

	local num = self:GetResearchedPerks()[nm]
	if not num then return false end

	return perk:GetLevel(num)
end

function PIN:HasPerkLevel(nm, need)
	if Research.IsPerkLevel(nm) then
		need = nm:GetLevel()
		nm = nm:GetPerk():GetID()
	end
	if Research.IsPerkLevel(need) then
		need = need:GetLevel()
	end

	return self:GetPerkLevelNumber(nm) >= need
end

function PIN:Research(lv)
	Research.ResearchLevel(self, lv)
end

PInfoAlias("GetPerkLevelNumber")
PInfoAlias("GetPerkLevel")
PInfoAlias("HasPerkLevel")
PInfoAlias("Research")

function Research.ResearchLevel(what, lv)
	assert(Research.IsPerkLevel(lv))
	local pin = GetPlayerInfoGuarantee(what)

	local perk = lv:GetPerk():GetID()
	assert(perk, "no perk?")

	if pin:GetPlayer() then
		pin:GetPlayer():GetResearchedPerks()[perk] = lv:GetLevel()
	end

	hook.Run("PlayerResearched", pin, lv:GetPerk(), lv)
end