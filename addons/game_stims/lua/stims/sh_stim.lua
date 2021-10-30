--wah

Stims = Stims or {}

Stims.Active = {}	   						-- stores [ply] = { activeStimStats }
Stims.PlayerStims = Stims.PlayerStims or {} -- stores [ply] = { stimStats }
Stims.ActionName = "Stim"
Stims.OffhandTable = Stims.OffhandTable or {
	Use = function() Stims.UseStim() end
}

if CLIENT then
	Offhand.Register(Stims.ActionName, Stims.OffhandTable)

	LibItUp.OnLoaded("darkhud.lua", function()
		include("stims/cl_stim_darkhud_ext.lua")
	end)
end

local blank_tbl = {}

function Stims.AddStim(ply, dat)
	dat = dat or Stims.PlayerStims[ply] or blank_tbl

	Stims.Active[ply] = {
		Working = false,		-- is the stimpak healing currently?
		Started = CurTime(),	-- when was the stimpak procced?

		-- delay before the stim actually starts healing
		WorkTime = dat.WorkTime or STIMPAK_WORK_TIME,

		-- delay between the stim stopping to heal and the stim being outta your hand
		DeinjectTime = dat.RemoveTime or STIMPAK_REMOVE_TIME,

		Heal = dat.HealAmount or 75,	-- how much HP the stim will heal
		HealTime = dat.HealTime or 1.5,	-- how much time will it take to heal

		LastHeal = 0, -- internal
	}

	hook.Run("PlayerUsedStimpak", ply, Stims.Active[ply])
end

function Stims.RemoveStim(ply)
	Stims.Active[ply] = nil
end


function Stims.SetStim(ply, dat)
	Stims.PlayerStims[ply] = dat
end

function PLAYER:GetStims()
	return self:GetNW2Int("Stimpaks", 0)
end

function PLAYER:GetMaxStims()
	return 2
end

function PLAYER:AddStims(num, ignore)
	if self:GetStims() >= self:GetMaxStims() and not ignore then return false end
	if not num then num = 1 end

	local add = ignore and num or math.min(self:GetMaxStims() - self:GetStims(), num)
	self:SetNW2Int("Stimpaks", self:GetStims() + num)
	return true
end

function PLAYER:TakeStims(num)
	if self:GetStims() <= 0 then return false end
	if not num then num = 1 end

	self:SetNW2Int("Stimpaks", self:GetStims() - num)
	return true
end

function PLAYER:GetStimCooldown(num)
	return 5
end

function PLAYER:IsOnStimCooldown()
	local lastUsed = self:GetNW2Float("UsedStimpak", 0)
	local left = self:GetStimCooldown(num) - (CurTime() - (lastUsed or 0))
	local frac = math.min((self:GetStimCooldown(num) - left) / self:GetStimCooldown(num), 1)

	return left > 0, left, frac
end

hook.Add("CanUseStimpak", "CountCheck", function(ply)
	if ply:GetStims() <= 0 then return false end
end)

hook.Add("CanUseStimpak", "CooldownCheck", function(ply)
	if ply:IsOnStimCooldown() then return false end
end)

hook.Add("PlayerSpawn", "ResetStimpaks", function(ply)
	ply:SetNW2Int("Stimpaks", 0)
end)

hook.Add("PlayerUsedStimpak", "UseStim", function(ply, dat)
	ply:TakeStims(1)
	ply:SetNW2Float("UsedStimpak", CurTime())

	if SERVER then

		ply:Timer("stim_sound", dat.WorkTime - 0.06, 1, function()
			local heal_amt = ply:GetMaxHealth() - ply:Health()
			local pitch = Lerp(heal_amt / dat.Heal, 170, 90)
			local lv = Lerp(heal_amt / dat.Heal, 40, 80)
			ply:EmitSound(Stims.Sound("healthshot_success_01"), lv, pitch)
		end)

	end
end)

local lkup = {}
for k,v in ipairs(file.Find("sound/stims/*", "GAME")) do
	local key = v:match("_(.+)%.mp3")
	lkup[key] = v
	lkup[v:match("(.+)%.mp3")] = v
end

local fmt = "stims/%s"

function Stims.Sound(name)
	name = tostring(name)
	name = name:gsub("%.mp3$", "")

	if not lkup[name] then errorf("no stim sound: %s", name) return end

	return fmt:format(lkup[name] or "")
end


function Stims.AllSounds()
	return lkup
end