--
local tree = Research.Tree or Object:callable()
Research.Tree = tree

Research.Trees = {} -- dump old trees

ChainAccessor(tree, "_Name", "Name")
ChainAccessor(tree, "_Description", "Description")
ChainAccessor(tree, "_Perks", "Perks")

function tree:Initialize(name)
	self:SetName(name)
	self:SetPerks({})
	self:SetDescription("")

	Research.Trees[name] = self
end

function tree:LoadPerks()
	for k,v in pairs(Research.Perks) do
		if v:GetTreeName() == self:GetName() then
			self:GetPerks()[v:GetID()] = v
		end
	end
end

function tree:AddPerk(v)
	self:GetPerks()[v:GetID()] = v
end

function Research.GetTree(name)
	local ret = Research.Trees[name] or tree:new(name)
	Research.Trees[name] = ret

	return ret
end

function Research.GetTrees()
	local t = {}

	for k,v in pairs(Research.Perks) do
		if v:GetTreeName() and not t[v:GetTreeName()] then
			t[v:GetTreeName()] = Research.GetTree(v:GetTreeName())
		end

		if t[v:GetTreeName()] then
			t[v:GetTreeName()]:AddPerk(v)
		end
	end

	return t
end