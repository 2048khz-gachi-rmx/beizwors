local ENTITY = FindMetaTable("Entity")
local PLAYER = FindMetaTable("Player")

BaseWars.Ents = BaseWars.Ents or {}

-- returns PlayerInfo, worldspawn or false
function ENTITY:BW_GetOwner()
	if SERVER then
		if self.CPPI_OwnerSID then
			return (GetPlayerInfo(self.CPPI_OwnerSID)), false
		end
	else
		local id = BaseWars.Ents.EntityToSteamID(self)

		if isstring(id) then
			return (GetPlayerInfo(id)), false
		end
	end

	local o1, o2 = self:CPPIGetOwner()

	if o1 == nil and o2 == nil then
		return false, true
	end
end

function ENTITY:BW_IsOwner(what)
	local pin = GetPlayerInfo(what)
	local ow = self:BW_GetOwner()

	if not ow or not pin then return false end
	return pin == ow
end