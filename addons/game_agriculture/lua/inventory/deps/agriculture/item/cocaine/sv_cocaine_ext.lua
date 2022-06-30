local cock = Agriculture.MetaCocaine
local cocks = Agriculture.CocaineTypes

cock.Duration = 5

function cocks.Vigorous:Activate(ply, str)

end

function cocks.Remedial:Activate(ply, str)

end

function cocks.Thorny:Activate(ply, str)
	print("activated roidrage", ply, str)
end

hook.Add("EntityTakeDamage", "RoidRage", function(tgt, dmg)
	local atk = dmg:GetAttacker()
	if not IsPlayer(atk) or atk == tgt then return end

	local rd = atk:HasCocaineEffect("Roid Rage")
	if not rd then return end

	local str = rd[2]
	local drug = Agriculture.GetDrug("Roid Rage")
	print("has roid rage", rd[2], 1 + drug.GetStrength(str))

	dmg:ScaleDamage(1 + drug.GetStrength(str))
end)

function cocks.Numbing:Activate(ply, str)

end

function cocks.Stout:Activate(ply, str)

end

local PLAYER = FindMetaTable("Player")

Agriculture.Junkies = Agriculture.Junkies or {}
local jk = Agriculture.Junkies

function PLAYER:ApplyCocaine(id, str)
	self._cocks = self._cocks or {}

	local nw = self:GetPublicNW()
	local t = {CurTime() + cock.Duration, str}

	nw:Set("cx_" .. id, t)
	self._cocks[id] = t

	if not table.HasValue(jk, self) then
		jk[#jk + 1] = self
	end

	cocks[Agriculture.CocaineIDToName(id)]:Activate(self, str)
end



function cock:PlayerUse(ply)
	local proc = self:GetProcessed()
	if not proc then print(ply, " tried to use unprocessed cocaine") return end

	local fx = self:GetEffects()

	for k,v in pairs(fx) do
		ply:ApplyCocaine(k, v)
	end
end

timer.Create("CocaineCheck", 0.5, 0, function()
	local ct = CurTime()

	for i=#jk, 1, -1 do
		local ply = jk[i]
		if not ply:IsValid() then table.remove(jk, i) continue end

		for k,v in pairs(ply._cocks) do
			local t = v[1]
			if ct > t then -- effect ran out
				ply._cocks[k] = nil
				continue
			end
		end

		-- no more effects left
		if table.IsEmpty(ply._cocks) then
			table.remove(jk, i)
		end
	end
end)

-- cocks.Vigorous
-- cocks.Remedial
-- cocks.Thorny
-- cocks.Numbing
-- cocks.Stout