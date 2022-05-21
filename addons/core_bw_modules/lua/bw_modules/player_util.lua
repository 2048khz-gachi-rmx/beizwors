local tag = "BaseWars.Util_Player"
local PLAYER = debug.getregistry().Player

BaseWars.Util_Player = {}
local MODULE = BaseWars.Util_Player

if SERVER then

	util.AddNetworkString(tag)

end

function MODULE.HandleNetMessage(len, ply)

	local Mode = net.ReadUInt(1)

	if CLIENT then

		local ply = LocalPlayer()

		if Mode == 0 then

			local text = net.ReadString()
			local col = net.ReadColor()

			MODULE.Notification(ply, text, col)

		end

	end

end

net.Receive(tag, MODULE.HandleNetMessage)

function MODULE.Notification(ply, ...)
	if SERVER then
		if isstring(select(1, ...)) and IsColor(select(2, ...)) then
			BaseWars.Notify.ChatNotify({select(2, ...), select(1, ...)})
			net.Send(ply)
		else
			BaseWars.Notify.ChatNotify(...)
			net.Send(ply)
		end
	else
		if isstring(select(1, ...)) and IsColor(select(2, ...)) then
			BaseWars.Notify.ChatNotify({select(2, ...), select(1, ...)})
		else
			BaseWars.Notify.ChatNotify(...)
		end
	end
end

local notification = MODULE.Notification
Notify = notification
PLAYER.Notify = notification
PLAYER.ChatNotify = notification

function PLAYER:LogNotify(...)
	BaseWars.Notify.LogNotify(...)
	net.Send(self)
end

function MODULE.PopupNotification(ply, typ, text, ...)
	BaseWars.Notify.PopupNotify(isnumber(typ) and typ or NOTIFY_GENERIC, text, ...)
	if SERVER then net.Send(ply) end
end

PLAYER.PopupNotify = MODULE.PopupNotification

function MODULE.NotificationAll(text, col)

	MODULE.Notification(nil, text, col)

end
NotifyAll = (MODULE.NotificationAll)

function MODULE.Spawn(ply)

	local col = ply:GetInfo("cl_playercolor")
	ply:SetPlayerColor(Vector(col))

	local col = Vector(ply:GetInfo("cl_weaponcolor"))

	if col:Length() == 0 then

		col = Vector(0.001, 0.001, 0.001)

	end

	ply:SetWeaponColor(col)

end
hook.Add("PlayerSpawn", tag .. ".Spawn", (MODULE.Spawn))

function MODULE.EnableFlashlight(ply)

	ply:AllowFlashlight(true)

end

hook.Add("PlayerSpawn", tag .. ".EnableFlashlight", (MODULE.EnableFlashlight))

function MODULE.PlayerSetHandsModel(ply, ent)

	local PlayerModel 	= player_manager.TranslateToPlayerModelName(ply:GetModel())
	local HandsInfo 	= player_manager.TranslatePlayerHands(PlayerModel)

	if HandsInfo then

		ent:SetModel(HandsInfo.model)
		ent:SetSkin(HandsInfo.skin)
		ent:SetBodyGroups(HandsInfo.body)

	end

end
hook.Add("PlayerSetHandsModel", tag .. ".PlayerSetHandsModel", (MODULE.PlayerSetHandsModel))

local traceOut = {}

local traceIn = {
	--mask = MASK_SOLID,
	collisiongroup = COLLISION_GROUP_PLAYER,
	output = traceOut,
}


function MODULE.Stuck(ply, pos)

	local t = traceIn
	local o = traceOut

	t.start 	= pos or ply:GetPos()
	t.endpos 	= t.start
	t.filter 	= ply
	t.mins 		= ply:OBBMins()
	t.maxs 		= ply:OBBMaxs()

	util.TraceHull(t)

	local ent = o.Entity

	return o.StartSolid or (ent and (ent:IsWorld() or IsValid(ent)))

end
PLAYER.Stuck = (MODULE.Stuck)

local function FindPassableSpace(ply, direction, step)

	local OldPos = ply:GetPos()
	local Origin = ply:GetPos()

	for i = 1, 11 do
		Origin = Origin + (step * direction)

		if not ply:Stuck(Origin) then return true, Origin end

	end

	return false, OldPos

end

function MODULE.UnStuck(ply, ang, scale)

	local NewPos = ply:GetPos()
	local OldPos = NewPos

	if not ply:Stuck() then return end

	local Ang = ang or ply:GetAngles()

	local Forward 	= Ang:Forward()
	local Right 	= Ang:Right()
	local Up 		= Ang:Up()

	local SearchScale = scale or 3
	local Found

	Found, NewPos = FindPassableSpace(ply, Forward, -SearchScale)

	if not Found then

		Found, NewPos = FindPassableSpace(ply, Right, SearchScale)

		if not Found then

			Found, NewPos = FindPassableSpace(ply, Right, -SearchScale)

			if not Found then

				Found, NewPos = FindPassableSpace(ply, Up, -SearchScale)

				if not Found then

					Found, NewPos = FindPassableSpace(ply, Up, SearchScale)

					if not Found then

						Found, NewPos = FindPassableSpace(ply, Forward, SearchScale)

						if not Found then

							return false

						end

					end

				end

			end

		end

	end

	if OldPos == NewPos then

		return false

	else

		ply:SetPos(NewPos)
		return true

	end

end
PLAYER.UnStuck = (MODULE.UnStuck)