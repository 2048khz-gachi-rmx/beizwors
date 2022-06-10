local bleaf = Agriculture.BaseLeaf
local ileaf = Agriculture.MetaLeaf
local typs = bleaf.Types

function ileaf:GetName()
	local typ = self:GetType()
	local base = self:GetBase():GetName()

	if typ and typ.Name then
		return ("%s %s"):format(typ.Name, base)
	else
		return base
	end
end

function ileaf:PostGenerateText(cloud, markup)
	
end

function ileaf:GetModelColor()
	local typ = self:GetType()
	if typ then
		return typ.Color
	end

	return color_white
end