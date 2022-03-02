AddCSLuaFile()

local base = "bw_base_electronics"
ENT.Base = base
ENT.Type = "anim"
ENT.PrintName = "Base Upgradable"

ENT.Levels = {
	[1] = {
		Cost = 0,
		PowerMult = 1,
	},
}

function ENT:Initialize()
	self:BaseRecurseCall("Initialize")
end

-- for override:
function ENT:OnUpgrade()
end

function ENT:OnFinalUpgrade()
end

function ENT:SetupDataTables()
	scripted_ents.GetStored(base).t.SetupDataTables(self)

	self:NetworkVar("Int", 1, "Level")
	self:SetLevel(1)

	if CLIENT then
		self:NetworkVarNotify("Level", function(self, key, old, new)
			if old == new or new == 1 then return end

			self:Timer("rubatfixWHEN", 0, 1, function()
				if self:GetLevel() == 1 then return end
				if new == self._LastUpgrade then return end

				self._LastUpgrade = new
				self:OnFinalUpgrade()
			end)
		end)
	end

	self:NetworkVar("Float", 1, "BoughtPrice")
	if SERVER and self.BoughtCost then
		self:SetBoughtPrice(self.BoughtCost)
	end
end

function ENT:GetUpgradeCost(curLv)
	curLv = curLv or self:GetLevel()
	curLv = curLv + 1
	return self.Levels[curLv] and self.Levels[curLv].Cost
end

function ENT:Upgrade_HasMoney(ply)
	local dat = self:GetUpgradeCost(self:GetLevel())
	local datNext = self:GetUpgradeCost(self:GetLevel() + 1)

	local plyM = ply:GetMoney()

	return plyM >= dat and dat,
		datNext and plyM >= dat + datNext
end

function ENT:GetLevelData(lv)
	lv = lv or self:GetLevel()

	-- autorefresh = goode
	local ent_base = scripted_ents.GetStored(self:GetClass()).t
	return ent_base.Levels and ent_base.Levels[lv] or self.Levels[lv]
end


function ENT:DoUpgrade(final)
	local lvl = self:GetLevel()
	local calcM = self:GetUpgradeCost(lvl)

	BaseWars.Worth.Add(self, calcM)

	self:SetLevel(lvl + 1)
	self:OnUpgrade(lvl + 1)

	local dat = self:GetLevelData()
	-- get the current level's power mult or the last defined one
	self._PowerMult = dat and dat.PowerMult or self._PowerMult or 1

	self:SetConsumptionMult_Add("LevelPower", self._PowerMult)

	if final then
		self:EmitSound("replay/rendercomplete.wav")
		self:OnFinalUpgrade(lvl + 1)
	end
end

function ENT:CanUpgradeTimes()
	return (self.MaxLevel or #self.Levels) - self:GetLevel()
end

function ENT:RequestUpgrade(ply, try, total)
	if not ply then return end
	local ow = self:BW_GetOwner()

	if GetPlayerInfo(ply) ~= ow then
		ply:ChatNotify({BASEWARS_NOTIFICATION_ERROR, "You can't upgrade others' machines!"})
		return false
	end

	if self:CanUpgradeTimes() == 0 then
		ply:ChatNotify({BASEWARS_NOTIFICATION_ERROR,
			Language.UpgradeMaxLevel(self.MaxLevel or #self.Levels)})
		return false
	end

	local has, hasNext = self:Upgrade_HasMoney(ply)

	if has == 0 then
		ply:ChatNotify({BASEWARS_NOTIFICATION_ERROR, "Unsetup upgrade cost (0)."})
		return
	end

	if not has then
		if try == 1 then
			ply:ChatNotify({BASEWARS_NOTIFICATION_ERROR, Language.UpgradeNoMoney()})
		end
		return false
	end

	ply:TakeMoney(has)

	self:DoUpgrade( (try == total) or not hasNext )
end