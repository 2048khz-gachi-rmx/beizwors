local perk = Research.Perk or Object:callable()
Research.Perk = perk
perk.IsResearchPerk = true

local level = Research.PerkLevel or Object:callable()
Research.PerkLevel = level
level.IsResearchPerkLevel = true

function Research.IsPerk(w)
	return istable(w) and w.IsResearchPerk
end

function Research.IsPerkLevel(w)
	return istable(w) and w.IsResearchPerkLevel
end

ChainAccessor(perk, "_ID", "ID")
ChainAccessor(perk, "_Name", "Name")
ChainAccessor(perk, "_Icon", "Icon")
ChainAccessor(perk, "_Levels", "Levels")
ChainAccessor(perk, "_TreeName", "TreeName")

Research.Perks = Research.Perks or {}

function perk:Initialize(id)
	self:SetID(id)
	self:SetName(id)

	if CLIENT then
		self:SetIcon(Icons.Star)
	end

	self:SetLevels({})
	Research.Perks[id] = self
end

function perk:GetLevel(lv)
	return self:GetLevels()[lv]
end

function perk:GetIcon(lv)
	lv = self:GetLevel(lv)
	return lv and lv:GetIcon() or self._Icon
end

function perk:GetName(lv)
	lv = self:GetLevel(lv)
	return lv and lv:GetName() or self._Name
end

function perk:AddLevel(i)
	i = i or #self:GetLevels() + 1
	local ret = level:new(i)
	ret._levelOf = self
	self:GetLevels()[i] = ret
	return ret
end

ChainAccessor(level, "_Name", "Name")
ChainAccessor(level, "_Icon", "Icon")

ChainAccessor(level, "_Level", "Level")

ChainAccessor(level, "_Requirements", "Requirements")
ChainAccessor(level, "_Requirements", "Reqs")

ChainAccessor(level, "_Prerequisites", "Prerequisites")
ChainAccessor(level, "_Prerequisites", "Prereqs")

function level:Initialize(lv)
	self:SetLevel(lv)
	self:SetReqs({ Items = {} })
	self:SetPrereqs({})

	self._pos = {0, 0}
end

function level:GetPerk()
	return self._levelOf
end

function level:SetPos(x, y)
	self._pos[1] = x
	self._pos[2] = y
end

function level:GetPos() return unpack(self._pos) end


function level:AddRequirement(what)
	local cur = self:GetRequirements()

	for k,v in pairs(what) do
		if not cur[k] then
			cur[k] = v
		else
			table.Merge(cur, what)
		end
	end
end