local perk = Research.Perk or Emitter:callable()
Research.Perk = perk
perk.IsResearchPerk = true

local level = Research.PerkLevel or Emitter:callable()
Research.PerkLevel = level
level.IsResearchPerkLevel = true

Research.Perks = Research.Perks or {} -- dump old perks

function Research.IsPerk(w)
	return istable(w) and w.IsResearchPerk
end

function Research.IsPerkLevel(w)
	return istable(w) and w.IsResearchPerkLevel
end

function Research.GetPerk(id)
	return Research.Perks[id]
end

ChainAccessor(perk, "_ID", "ID")
ChainAccessor(perk, "_Name", "Name")
ChainAccessor(perk, "_Icon", "Icon")
ChainAccessor(perk, "_Levels", "Levels")
ChainAccessor(perk, "_TreeName", "TreeName")
ChainAccessor(perk, "_Color", "Color")


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
	assert(i > 0, "Levels have to be > 0.")
	assert(math.floor(i) == i, "Can't add float levels.")

	i = i or #self:GetLevels() + 1
	local ret = level:new(i)
	ret._levelOf = self
	self:GetLevels()[i] = ret

	ret:SetNameFragments({
		self:GetName() or "?",
		" ",
		i
	})

	--ret:SetName(table.concat(ret:GetNameFragments()))

	if self:GetLevel(i - 1) and not noadd then
		ret:AddPrerequisite(self:GetLevel(i - 1))
	end

	return ret
end

ChainAccessor(level, "_NameFragments", "NameFragments")
ChainAccessor(level, "_Name", "Name")

ChainAccessor(level, "_Icon", "Icon")

ChainAccessor(level, "_Level", "Level")

ChainAccessor(level, "_Requirements", "Requirements")
ChainAccessor(level, "_Requirements", "Reqs")

ChainAccessor(level, "_Prerequisites", "Prerequisites")
ChainAccessor(level, "_Prerequisites", "Prereqs")
ChainAccessor(level, "_ResTime", "ResearchTime")

ChainAccessor(level, "_Description", "Description")
ChainAccessor(level, "_Color", "Color")

function level:SetIcon(ic)
	if SERVER then return end

	ic = ic:Copy()
	ic:SetAutosize(false)

	if not ic:GetSizeSet() then
		ic:SetSize(math.sin(math.pi / 4), math.sin(math.pi / 4))
	end

	self._Icon = ic
	return self
end

function level:Initialize(lv)
	self:SetLevel(lv)
	self:SetReqs({ Items = {} })
	self:SetPrereqs({})
	self:SetNameFragments({})
	self:SetResearchTime(15)

	self._pos = {0, 0}
end

function level:GetName()
	return table.concat(self:GetNameFragments(), "")
end

function level:SetName(n)
	errorNHf("dont use SetName; use SetNameFragments instead")
	return
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
		return ply:HasPerkLevel(name:GetPerk():GetID(), lv)
	end

	return true -- not implemented?
end

local colors = {
	["$"] = Colors.Money,
	["^"] = Colors.Sky,
	["#"] = Colors.Golden,
	["@"] = Colors.Red,
	["*"] = color_white,
	["&"] = Colors.Blue
}

function level:FillMarkup(mup)
	local ret = eval(self:GetDescription(), self, mup)

	if isstring(ret) then
		local t = {}
		local cols = {}

		local i = 0
		local pattern = "[%" .. table.concat(string.Prefixes, "%") .. "]"

		for s, match in eachMatch(ret, pattern .. "[^%s%p]+") do
			i = i + 2
			t[i - 1] = s
			t[i] = match and match:sub(2)
			cols[#cols + 1] = match and colors[match:sub(1, 1)] or Colors.Error
		end

		local pc = mup:AddPiece()
		pc:SetFont("BS20")
		pc:SetAlignment(1)
		pc:SetColor(160, 160, 160)

		local n = 0
		for i=1, #t, 2 do
			pc:AddText(t[i])
			if t[i + 1] then
				n = n + 1
				local num = pc:AddText(t[i + 1])
				num.color = cols[n] or Colors.Error
			end
		end
	end
end

function level:PrereqsSatisified()
	for k,v in pairs(self:GetPrereqs()) do
		if not self:PrereqSatisfied(k, ply, comp) then
			return false
		end
	end

	return true
end

function level:CanResearch(ply, comp)
	if not IsValid(comp) or not comp.ResearchComputer then return false end

	if comp:GetRSPerk() ~= "" then return false end

	-- check prereqs
	if not self:PrereqsSatisified() then
		return false, "Prerequisites not satisfied!"
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

function level:IsResearched(ply)
	if CLIENT then ply = CachedLocalPlayer() end
	return ply:HasPerkLevel(self)
end