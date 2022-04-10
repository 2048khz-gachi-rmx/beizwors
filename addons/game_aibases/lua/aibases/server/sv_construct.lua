--

function AIBases.ConstructLayout(lay)
	for k,v in pairs(lay.Bricks) do
		v:Spawn()
	end
end

function AIBases.ConstructBase(base)
	local lay = base:GetLayout()
end