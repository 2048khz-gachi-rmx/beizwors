
local PLAYER = debug.getregistry().Player

function PLAYER:SetDeathVar(k, v)
	local t = self:GetTable()

	t._deathVars = t._deathVars or {}
	t._deathVars[k] = v
end

PLAYER.SetTempVar = PLAYER.SetDeathVar
PLAYER.SetLifeVar = PLAYER.SetDeathVar

function PLAYER:GetDeathVar(k, def)
	local t = self:GetTable()
	local dv = t._deathVars

	if not dv or dv[k] == nil then return def end

	return dv[k]
end

PLAYER.GetTempVar = PLAYER.GetDeathVar
PLAYER.GetLifeVar = PLAYER.GetDeathVar


function PLAYER:AddHP(hp)
	local cur = self:Health()
	local lacking = math.max(0, self:GetMaxHealth() - cur)
	local add = math.min(hp, lacking)
	local intAdd, fr = math.modf(add)

	if fr ~= 0 then -- cant have fraction if we reached maxhp cuz neither hp nor max can be float
		local fh = self:GetDeathVar("fracHeal", 0)
		local fAdd, fKeep = math.modf(math.Round(fh + fr, 6)) -- I HATE FLOATING POINT!! I HATE FLOATING POINT!!!!!
		intAdd = intAdd + fAdd
		self:SetDeathVar("fracHeal", fKeep)
	end

	self:SetHealth(cur + intAdd)
end

PLAYER.AddHealth = PLAYER.AddHP

hook.Add("PostPlayerDeath", "EraseDeathVars", function(ply)
	hook.Run("DeathVarsErase", ply, ply._deathVars)
	ply._deathVars = nil
end)