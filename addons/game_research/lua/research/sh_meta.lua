--

local PLAYER = FindMetaTable("Player")


function PLAYER:GetPerkLevelNumber(nm)
	if Research.IsPerk(nm) then nm = nm:GetID() end
	return self:GetResearchedPerks()[nm] or 0
end

function PLAYER:GetPerkLevel(nm)
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

function PLAYER:HasPerkLevel(nm, need)
	if Research.IsPerkLevel(nm) then
		need = nm:GetLevel()
		nm = nm:GetPerk():GetID()
	end
	if Research.IsPerkLevel(need) then
		need = need:GetLevel()
	end

	return self:GetPerkLevelNumber(nm) >= need
end

function PLAYER:Research(lv)
	Research.ResearchLevel(self, lv)
end

function Research.ResearchLevel(what, lv)
	assert(Research.IsPerkLevel(lv))
	local pin = GetPlayerInfoGuarantee(what)

	local perk = lv:GetPerk():GetID()
	assert(perk, "no perk?")

	hook.Run("PlayerResearched", pin, lv:GetPerk(), lv)

	if pin:GetPlayer() then
		pin:GetPlayer():GetResearchedPerks()[perk] = lv:GetLevel()
	end
end