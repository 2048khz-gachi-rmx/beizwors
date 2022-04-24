BaseWars = BaseWars or {}

include("include.lua")

local AuthTbl = {}

function GM:NetworkIDValidated(name, steamid)
	AuthTbl[steamid] = name
end

function GM:PlayerInitialSpawn(ply)

	self.BaseClass:PlayerInitialSpawn(ply)

	BaseWars.UTIL.RefundFromCrash(ply)

	--[[local f = function()

		if not AuthTbl[ply:SteamID()] then
			ply:ChatPrint(Language("FailedToAuth"))
			ply.UnAuthed = true
		else
			AuthTbl[ply:SteamID()] = nil
		end

	end

	timer.Simple(0, f)]]

	for k, v in next, ents.GetAll() do

		local Owner = (IsValid(v) and v.CPPIGetOwner and IsValid(v:CPPIGetOwner())) and v:CPPIGetOwner()
		local Class = v:GetClass()
		if Owner ~= ply or not Class:find("bw_") then continue end

		ply:GetTable()["limit_" .. Class] = (ply:GetTable()["limit_" .. Class] or 0) + 1

	end

	timer.Simple(0, function()
		if ply:GetFaction() then
			ply:SetTeam(ply:GetFaction():GetID())
		else
			ply:SetTeam(Factions.FactionlessTeamID)
		end
	end)

end

function GM:GetGameDescription()
	return self.Name
end

function GM:ShutDown()
	BaseWars.UTIL.SafeShutDown()
	BaseWars.PlayerData.SyncBWIntoSQL()
	self.BaseClass:ShutDown()
end

function GM:OnEntityCreated(ent)
	self.BaseClass:OnEntityCreated(ent)

	local f = function()

		local Class = IsValid(ent) and ent:GetClass()
		if not Class then return end

		local should = Class == "prop_physics"
		should = should or ent:Health() == 0 and ent:GetMaxHealth() == 0

		if not should then return end

		local HP = (IsValid(ent:GetPhysicsObject()) and ent:GetPhysicsObject():GetMass() or 50) * BaseWars.Config.UniversalPropConstant
		HP = math.Clamp(HP, 0, Class == "prop_physics" and 1000 or 50)

		ent:SetHealth(HP)

		ent.MaxHealth = math.Round(HP)
		ent.DestructableProp = Class == "prop_physics"

		ent:SetMaxHealth(ent.MaxHealth)
	end

	timer.Simple(0, f)

end

function GM:SetupPlayerVisibility(ply)
	self.BaseClass:SetupPlayerVisibility(ply)
end

function GM:PreCleanupMap()
	BaseWars.UTIL.RefundAll()
end

function GM:PostCleanupMap()

end

function GM:GetFallDamage(ply, speed)

	local Velocity = speed - 526.5

	return Velocity * 0.225

end

--[[
function GM:SetupMove(ply, move)

	local State = self.BaseClass:SetupMove(ply, move)

	if not ply:Alive() then

		return State

	end

	return State

end
]]

function GM:KeyPress(ply, code)
	self.BaseClass:KeyPress(ply, code)

	if code == IN_JUMP and
		ply:GetMoveType() == MOVETYPE_WALK and
		(ply.Stuck and ply:Stuck()) then
		ply:UnStuck()
	end
end

function GM:EntityTakeDamage(ent, dmginfo)
	if ent.CanTakeDamage == false then return true end
	if not IsValid(ent) then return end

	local isPly = ent:IsPlayer()
	local isNpc = ent:IsNextBot() or ent:IsNPC()

	if dmginfo:IsDamageType(DMG_BURN) and not (isPly or isNpc) then
		ent:Extinguish()
		return true
	end

	self.BaseClass:EntityTakeDamage(ent, dmginfo)

	local Inflictor = dmginfo:GetInflictor()
	local Attacker 	= dmginfo:GetAttacker()

	if not isPly and not isNpc then
		-- custom logic goes first
		local ret = hook.Run("BW_CanDealEntityDamage", Attacker, ent, Inflictor, dmginfo)
		if ret ~= nil then
			if ret then
				BaseWars.DealDamage(ent, dmginfo)
			end

			return not ret
		end
	end

	-- raid logic comes after
	local raidRet = BaseWars.Raid.CanDealDamage(Attacker, ent, Inflictor, dmginfo)

	if raidRet ~= nil then
		if raidRet then
			BaseWars.DealDamage(ent, dmginfo)
		end

		return not raidRet
	end

	if isPly then
		if not Attacker:IsPlayer() and dmginfo:IsDamageType(DMG_CRUSH) and
			(Attacker:IsWorld() or (IsValid(Attacker) and not Attacker:CreatedByMap())) then
			dmginfo:SetDamage(0)
			return
		end

		local FriendlyFire = BaseWars.Config.AllowFriendlyFire

		if ent ~= Attacker and not FriendlyFire
			and ent:InFaction() and Attacker:IsPlayer()
			and Attacker:InFaction(ent) then
			dmginfo:SetDamage(0)
			return
		end
	end

end

local SpawnClasses = {
	["info_player_deathmatch"] = true,
	["info_player_rebel"] = true,
	["gmod_player_start"] = true,
	["info_player_start"] = true,
	["info_player_allies"] = true,
	["info_player_axis"] = true,
	["info_player_counterterrorist"] = true,
	["info_player_terrorist"] = true,
}

local LastThink = CurTime()
local Spawns 	= {}

local function ScanEntities()
	Spawns = {}

	for k, v in next, ents.GetAll() do

		if not v or not IsValid(v) or k < 1 then continue end

		local Class = v:GetClass()

		if SpawnClasses[Class] then

			Spawns[#Spawns+1] =  v

		end

	end
end

local mults = {
	[HITGROUP_LEFTARM] = 4, [HITGROUP_RIGHTARM] = 4, -- 100% to anywhere on the body
	[HITGROUP_LEFTLEG] = 3, [HITGROUP_RIGHTLEG] = 3, -- 75% to the legs
}

function GM:ScaleNPCDamage(npc, hg, dmg)
	local ret = self.BaseClass.ScaleNPCDamage and self.BaseClass.ScaleNPCDamage(self, npc, hg, dmg)

	if ret then return ret end

	if mults[hg] then
		dmg:ScaleDamage(mults[hg])
	end
end

--[[
function GM:PlayerShouldTakeDamage(ply, atk)

	if aowl and ply.Unrestricted then

		return false

	end

	if ply == atk then

		return true

	end

	for k, v in next, ents.FindInSphere(ply:GetPos(), 256) do

		local Class = v:GetClass()

		if SpawnClasses[Class] then

			if BaseWars.Ents:ValidPlayer(atk) then

				atk:Notify(BaseWars.LANG.SpawnKill, BASEWARS_NOTIFICATION_ERROR)

			end

			return false

		end

	end

	for k, v in next, ents.FindInSphere(atk:GetPos(), 256) do

		local Class = v:GetClass()

		if SpawnClasses[Class] then

			if BaseWars.Ents:ValidPlayer(atk) then

				atk:Notify(BaseWars.LANG.SpawnCamp, BASEWARS_NOTIFICATION_ERROR)

			end

			return false

		end

	end

	return true

end
]]
function GM:PostPlayerDeath(ply)

end

function GM:PlayerDisconnected(ply)

	BaseWars.UTIL.ClearRollbackFile(ply)

	self.BaseClass:PlayerDisconnected(ply)

end

function GM:Think()

	local State = self.BaseClass:Think()

	if LastThink < CurTime() - 5 then

		for k, s in ipairs(Spawns) do
			if not s or not IsValid(s) then
				ScanEntities()
				return State
			end

			local Ents = ents.FindInSphere(s:GetPos(), 256)

			if #Ents < 2 then
				continue
			end

			for _, v in ipairs(Ents) do

				if v.BeingRemoved or v.NoFizz then
					continue
				end

				local Owner = v:CPPIGetOwner()

				if not Owner or not IsValid(Owner) or not Owner:IsPlayer() then
					continue
				end

				if v:GetClass() == "prop_physics" then
					v.BeingRemoved = true
					v:Remove()

					Owner:Notify(BaseWars.LANG.DontBuildSpawn, BASEWARS_NOTIFICATION_ERROR)
				end
			end
		end

		LastThink = CurTime()

	end

	return State

end

function GM:InitPostEntity()

	self.BaseClass:InitPostEntity()

	ScanEntities()

	for k, v in next, ents.FindByClass("*door*") do
		v:Fire("unlock")
	end
end

function GM:PlayerSpawn(ply)

	self.BaseClass:PlayerSpawn(ply)
	self:SetPlayerSpeed(ply, BaseWars.Config.DefaultWalk, BaseWars.Config.DefaultRun)

	local Spawn = ply.SpawnPoint

	if IsValid(Spawn) then
		Spawn:RespawnPlayer(ply)
	end

	for k, v in next, BaseWars.Config.SpawnWeps do
		ply:Give(v)
	end

	if ply:HasWeapon("hands") then
		ply:SelectWeapon("hands")
	elseif ply:HasWeapon("none") then
		ply:SelectWeapon("none")
	end
end

ScanEntities()
BaseWars.LoadLog("Initialized.")