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
ChainAccessor(perk, "_Color", "Color")

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

function perk:AddLevel(i, noadd)
	i = i or #self:GetLevels() + 1
	local ret = level:new(i)
	ret._levelOf = self
	self:GetLevels()[i] = ret

	ret:SetNameFragments({
		self:GetName() or "?",
		" ",
		i
	})

	if self:GetLevel(i - 1) and not noadd then
		ret:AddPrerequisite(self:GetLevel(i - 1))
	end

	return ret
end

ChainAccessor(level, "_NameFragments", "NameFragments")
ChainAccessor(level, "_Icon", "Icon")

ChainAccessor(level, "_Level", "Level")

ChainAccessor(level, "_Requirements", "Requirements")
ChainAccessor(level, "_Requirements", "Reqs")

ChainAccessor(level, "_Prerequisites", "Prerequisites")
ChainAccessor(level, "_Prerequisites", "Prereqs")

ChainAccessor(level, "_Description", "Description")
ChainAccessor(level, "_Color", "Color")

function level:Initialize(lv)
	self:SetLevel(lv)
	self:SetReqs({ Items = {} })
	self:SetPrereqs({})
	self:SetNameFragments({})

	self._pos = {0, 0}
end

function level:GetName()
	return table.concat(self:GetNameFragments(), "")
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

function level:AddPrerequisite(req, v)
	local cur = self:GetPrereqs()
	cur[req] = v or true
end

function level:PrereqSatisfied(name, ply, comp)
	if Research.IsPerkLevel(name) then
		local lv = name:GetLevel()
		return ply:GetPerkLevel(name:GetPerk():GetID()) >= lv
	end

	return true -- not implemented?
end

function level:CanResearch(ply, comp)
	if not IsValid(comp) or not comp.ResearchComputer then return false end

	-- check prereqs
	for k,v in pairs(self:GetPrereqs()) do
		if not self:PrereqSatisfied(k, ply, comp) then
			return false, "Prerequisites not satisfied!"
		end
	end
		
	-- check reqs: items
	local its = self:GetRequirements().Items

	local baseErr = ""
	local err = ""

	if its then
		local miss = {}
		local inv = Inventory.GetTemporaryInventory(ply)
		for id, need in pairs(its) do
			local cnt = Inventory.Util.GetItemCount(inv, id)

			if cnt < need then
				miss[#miss + 1] = {id, cnt, need}
			end
		end

		if miss[1] then
			baseErr = "You don't have enough "

			for k,v in ipairs(miss) do
				local base = Inventory.Util.GetBase(v[1])
				if not base then continue end
				err = err .. base:GetName() .. (miss[k + 1] and ", " or "")
			end

			return false, baseErr .. err .. "."
		end
	end

	return true
end