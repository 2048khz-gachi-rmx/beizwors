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

	self.BaseClass:ShutDown()

end

function GM:OnEntityCreated(ent)

	local f = function()

		self.BaseClass:OnEntityCreated(ent)

		local Class = IsValid(ent) and ent:GetClass()
		if Class == "prop_physics" and ent:Health() == 0 then

			local HP = (IsValid(ent:GetPhysicsObject()) and ent:GetPhysicsObject():GetMass() or 50) * BaseWars.Config.UniversalPropConstant
			HP = math.Clamp(HP, 0, 1000)

			ent:SetHealth(HP)

			ent.MaxHealth = math.Round(HP)
			ent.DestructableProp = true

			ent:SetNW2Int("MaxHealth", ent.MaxHealth)

			ent:SetMaxHealth(ent.MaxHealth)
				timer.Create("prop"..ent:EntIndex(),1,0,function() if !(ent:IsValid()) then return end ent:SetNW2Int("MaxHealth",ent.MaxHealth) end)

				function ent:OnRemove()
					timer.Remove("prop"..self:EntIndex())
				end

		end

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

	local Player = ((IsValid(ent) and ent:IsPlayer()) and ent) or false
	if dmginfo:IsDamageType(DMG_BURN) and not Player then return true end

	local Owner = IsValid(ent) and ent.CPPIGetOwner and ent:CPPIGetOwner()
	Owner = (IsPlayer(Owner) and Owner) or false

	self.BaseClass:EntityTakeDamage(ent, dmginfo)

	local Inflictor = dmginfo:GetInflictor()
	local Attacker 	= dmginfo:GetAttacker()

	--local Damage 	= dmginfo:GetDamage()
	--local PropDamageScale = 0.5
	--local IsProp = ent:GetClass() == "prop_physics"

	if not ent:IsPlayer() then
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

	if ent:IsPlayer() then
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

	if IsValid(Spawn) and (not Spawn.IsPowered or Spawn:IsPowered()) then
		local Pos = Spawn:GetPos() + Vector(0, 0, 16)
		local ang = Spawn.SpawnAngle
		ang[1] = 0
		ang[3] = 0
		ply:SetPos(Pos)
		ply:SetEyeAngles(ang)
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
