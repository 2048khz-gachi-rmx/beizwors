local cock = Agriculture.MetaCocaine
local cocks = Agriculture.CocaineTypes

function cocks.Vigorous:Activate(ply)

end

function cocks.Remedial:Activate(ply)

end

function cocks.Thorny:Activate(ply)

end

function cocks.Numbing:Activate(ply)

end

function cocks.Stout:Activate(ply)

end

function cock:PlayerUse(ply)
	local proc = self:GetProcessed()
	--if not proc then print(ply, " tried to use unprocessed cocaine") return end
end

-- cocks.Vigorous
-- cocks.Remedial
-- cocks.Thorny
-- cocks.Numbing
-- cocks.Stout