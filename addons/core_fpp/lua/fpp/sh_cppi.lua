CPPI = CPPI or {}

if SERVER then
	function ENTITY:CPPISetOwnerUID(UID)
		local ply = UID and player.GetByUniqueID(tostring(UID)) or nil
		if UID and not IsValid(ply) then return false end
		return self:CPPISetOwner(ply)
	end

	function ENTITY:CPPICanTool(ply, tool)
		local Value = FPP.Protect.CanTool(ply, nil, tool, self)
		if Value ~= false and Value ~= true then Value = true end
		return Value
	end

	function ENTITY:CPPICanPhysgun(ply)
		return FPP.plyCanTouchEnt(ply, self, "Physgun")
	end

	function ENTITY:CPPICanPickup(ply)
		return FPP.plyCanTouchEnt(ply, self, "Gravgun")
	end

	function ENTITY:CPPICanPunt(ply)
		return FPP.plyCanTouchEnt(ply, self, "Gravgun")
	end

	function ENTITY:CPPICanUse(ply)
		return FPP.plyCanTouchEnt(ply, self, "PlayerUse")
	end

	function ENTITY:CPPICanDamage(ply)
		return FPP.plyCanTouchEnt(ply,  self, "EntityDamage")
	end

	function ENTITY:CPPIDrive(ply)
		local Value = FPP.Protect.CanDrive(ply, self)
		if Value ~= false and Value ~= true then Value = true end
		return Value
	end

	function ENTITY:CPPICanProperty(ply, property)
		local Value = FPP.Protect.CanProperty(ply, property, self)
		if Value ~= false and Value ~= true then Value = true end
		return Value
	end

	function ENTITY:CPPICanEditVariable(ply, key, val, editTbl)
		return self:CPPICanProperty(ply, "editentity")
	end
end

CPPI = CPPI or {}
CPPI.CPPI_DEFER = 102112 --\102\112 = fp
CPPI.CPPI_NOTIMPLEMENTED = 7080 --\70\80 = FP

function CPPI:GetName()
	return "Falco's prop protection"
end

function CPPI:GetVersion()
	return "universal.1"
end

function CPPI:GetInterfaceVersion()
	return 1.3
end

function CPPI:GetNameFromUID(uid)
	return CPPI.CPPI_NOTIMPLEMENTED
end

local PLAYER = FindMetaTable("Player")
function PLAYER:CPPIGetFriends()
	if not self.Buddies then return CPPI.CPPI_DEFER end
	local FriendsTable = {}

	for k, v in pairs(self.Buddies) do
		if not table.HasValue(v, true) then continue end -- not buddies in anything
		table.insert(FriendsTable, k)
	end

	return FriendsTable
end

local ENTITY = FindMetaTable("Entity")
function ENTITY:CPPIGetOwner()
	local Owner = FPP.entGetOwner(self)
	if not IsValid(Owner) or not Owner:IsPlayer() then return SERVER and Owner or nil, self.FPPOwnerID end
	return Owner, Owner:SteamID()
end

if SERVER then
	function ENTITY:CPPISetOwner(ply)
		if ply == self.FPPOwner then return end

		assert(ply == nil or IsEntity(ply), "The owner of an entity must be set to either nil, NULL or a valid entity.")

		local valid = IsValid(ply) and ply:IsPlayer()				-- Why the fuck is this a thing, falco?
		local steamId = valid and ply:SteamID() or nil							-- V
		local canSetOwner = hook.Run("CPPIAssignOwnership", ply, self, ply:SteamID64())

		if canSetOwner == false then return false end
		ply = canSetOwner ~= nil and canSetOwner ~= true and canSetOwner or ply
		hook.Run("CPPIAssignedOwnership", ply, self, ply:SteamID64())
		self.FPPOwner = ply
		self.FPPOwnerID = steamId
		self.FPPOwnerSID64 = valid and ply:SteamID64()

		self.FPPOwnerChanged = true
		FPP.recalculateCanTouch(player.GetAll(), {self})
		self.FPPOwnerChanged = nil

		return true
	end

	function ENTITY:CPPISetOwnerUID(UID)
		local ply = UID and player.GetByUniqueID(tostring(UID)) or nil
		if UID and not IsValid(ply) then return false end
		return self:CPPISetOwner(ply)
	end

	function ENTITY:CPPICanTool(ply, tool)
		local Value = FPP.Protect.CanTool(ply, nil, tool, self)
		if Value ~= false and Value ~= true then Value = true end
		return Value
	end

	function ENTITY:CPPICanPhysgun(ply)
		return FPP.plyCanTouchEnt(ply, self, "Physgun")
	end

	function ENTITY:CPPICanPickup(ply)
		return FPP.plyCanTouchEnt(ply, self, "Gravgun")
	end

	function ENTITY:CPPICanPunt(ply)
		return FPP.plyCanTouchEnt(ply, self, "Gravgun")
	end

	function ENTITY:CPPICanUse(ply)
		return FPP.plyCanTouchEnt(ply, self, "PlayerUse")
	end

	function ENTITY:CPPICanDamage(ply)
		return FPP.plyCanTouchEnt(ply,  self, "EntityDamage")
	end

	function ENTITY:CPPIDrive(ply)
		local Value = FPP.Protect.CanDrive(ply, self)
		if Value ~= false and Value ~= true then Value = true end
		return Value
	end

	function ENTITY:CPPICanProperty(ply, property)
		local Value = FPP.Protect.CanProperty(ply, property, self)
		if Value ~= false and Value ~= true then Value = true end
		return Value
	end

	function ENTITY:CPPICanEditVariable(ply, key, val, editTbl)
		return self:CPPICanProperty(ply, "editentity")
	end
end
