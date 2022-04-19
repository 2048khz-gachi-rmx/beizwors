local tag = "BaseWars.UTIL"
BaseWars.UTIL = {}
BW = BaseWars
bw = BaseWars
Bw = BaseWars

GM.Name 		= "BaseWars"

GM.Author 		= "Original: Q2F2, Ghosty, Liquid, Tenrys, Trixter, User4992\nModded: gachirmx"

GM.Credits		= [[
Original:

	Thanks to the following people:
		Q2F2			- Main backend dev.
		Ghosty			- Main frontent dev.
		Trixter			- Frontend + Several entities.
		Liquid			- Misc dev, good friend.
		Tenrys			- Misc dev, good friend also.
		Pyro-Fire		- Owner of LagNation, ideas ect.
		Devenger		- Twitch Weaponry 2
		User4992		- Fixes for random stuff.

	This GM has been built from scratch with almost no traces of the original BaseWars existing.
	2017 Re-released MIT version.
]]

GM.License = [[

basewars_free:
	Copyright (c) 2015-2017 Hexahedronic, Q2F2, Ghosty, Liquid, Tenrys, Trixter, User4992.

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Credits:
	]] .. GM.Credits .. [[

See GM.OGLicense for the basewars_free license.
See GM.OGCredits for the basewars_free credits.]]

local license = GM.License

GM.OGLicense = [[
Copyright (c) 2015-2017 Hexahedronic, Q2F2, Ghosty, Liquid, Tenrys, Trixter, User4992
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

GM.OGCredits = [[
Thanks to the following people:
	Q2F2			- Main backend dev.
	Ghosty			- Main frontent dev.
	Trixter			- Frontend + Several entities.
	Liquid			- Misc dev, good friend.
	Tenrys			- Misc dev, good friend also.
	Pyro-Fire		- Owner of LagNation, ideas ect.
	Devenger		- Twitch Weaponry 2
	User4992		- Fixes for random stuff.
This GM has been built from scratch with almost no traces of the original BaseWars existing.
2017 Re-released MIT version.
]]

GachiRP = true

function Deprecated()
	local str = [[!! Attempt to call deprecated function: "%s" !!]] .. "\n"

	local tr = debug.traceback()
	local caller

	local traced = false

	for s in string.gmatch(tr, "(%C+)%c") do

		if not isstring(s) then print(s, "not a string") return end
		for where, what in string.gmatch(s, "(.+) in (.+)") do
			if not caller then
				print(str:format(what))
				caller = what
			else
				if not traced then print("Stack traceback: \n") traced = true end
				local str = [[	From: %s
	What: %s]] .. "\n"
				print(str:format(where, what))
			end
		end

	end

end


function GM:GetGameDescription()
	return self.Name
end

function ents.FindInCone(cone_origin, cone_direction, cone_radius, cone_angle)

	local entities = ents.FindInSphere(cone_origin, cone_radius)
	local result = {}

	cone_direction:Normalize()

	local cos = math.cos(cone_angle)

	for _, entity in next, entities do

		local pos = entity:GetPos()
		local dir = pos - cone_origin
		dir:Normalize()

		local dot = cone_direction:Dot(dir)

		if dot > cos then

			table.insert(result, entity)

		end

	end

	return result

end

local temp = Vector()

function IsInCone(point, cone_origin, cone_dir, cone_radius, cone_angle)
	if cone_origin:Distance(point) > cone_radius then return false end

	cone_dir:Normalize()

	temp:Set(point)
	temp:Sub(cone_origin)
	temp:Normalize()

	local dot = cone_dir:Dot(temp)
	local cos = math.cos(cone_angle)

	if dot > cos then
		return true
	end

	return false
end

--ents.FindInCone = Deprecated

function BaseWars.IsXmasTime(day)

	local Month = tonumber(os.date("%m"))
	local Day	= tonumber(os.date("%d"))

	return Month == 12 and (not day or (Day == 24 or Day == 25))

end

BaseWars.IsXmasTime = Deprecated

function BaseWars.AddToSpawn(t)

	t.Limit = t.Limit or BaseWars.Config.DefaultLimit

	t.Price = t.Price or 420
	t.Level = t.Level or 0

	t.Model = t.Model or "models/Humans/Group01/Male_Cheaple.mdl"
	t.ShouldFreeze = (t.Gun and false) or (t.ShouldFreeze == nil and true) or t.ShouldFreeze
	t.Name = t.Name or "???"
	if not t.ClassName then
		error("look i'd put up with your shit like not setting limits or price but NOT CLASS NAME???")
		return
	end

	return t

end

BASEWARS_NOTIFICATION_ADMIN = color_white
BASEWARS_NOTIFICATION_ERROR = Color(225, 100, 100, 255)
BASEWARS_NOTIFICATION_MONEY = Color(0, 255, 0, 255)
BASEWARS_NOTIFICATION_RAID 	= Color(255, 255, 0, 255)
BASEWARS_NOTIFICATION_GENRL = Color(255, 0, 255, 255)
BASEWARS_NOTIFICATION_DRUG	= Color(0, 255, 255, 255)


local colorRed 		= Color(255, 0, 0)
local colorBlue 	= Color(0, 0, 255)
local colorWhite 	= Color(255, 255, 255)

function BaseWars.UTIL.RefundFromCrash(ply)

	--[[

	local UID = ply:SteamID64()
	local FileName = "basewars_crashrollback/" .. UID .. "_load.txt"

	if file.Exists(FileName, "DATA") then

		local Money = file.Read(FileName, "DATA")
		Money = tonumber(Money)
		if not Money then file.Delete(FileName) return end
		ply:ChatPrint(Language.WelcomeBackCrash)
		ply:ChatPrint(Language("Refunded", BaseWars.NumberFormat(Money)))

		print("Refunding ", ply, " for server crash previously.")
		ply:GiveMoney(Money)

		file.Delete(FileName)

	end

	]]

end

function BaseWars.UTIL.ClearRollbackFile(ply)

	local UID = ply:UniqueID()
	local FileName = "basewars_crashrollback/" .. UID .. "_save.txt"

	if file.Exists(FileName, "DATA") then file.Delete(FileName) end

end

function BaseWars.UTIL.SafeShutDown()
	BaseWars.UTIL.RefundAll()
	BaseWars.PlayerData.SyncBWIntoSQL()
end

function BaseWars.UTIL.FreezeAll()

	for k, v in next, ents.GetAll() do

		if not IsValid(v) then continue end

		local Phys = v:GetPhysicsObject()
		if not IsValid(Phys) then continue end

		Phys:EnableMotion(false)

	end

end

local NumTable = {
	[5] = {10^6 , "Million"},
	[4] = {10^9 , "Billion"},
	[3] = {10^12, "Trillion"},
	[2] = {10^15, "Quadrillion"},
	[1] = {10^18, "Quintillion"},
}

function BaseWars.NumberFormat(num)

	for i = 1, #NumTable do
		local Div = NumTable[i][1]
		local Str = NumTable[i][2]

		if num >= Div or num <= -Div then
			local frac = math.floor(num / Div * 10) / 10
			return string.Comma2(frac) .. " " .. Str

		end
	end

	return string.Comma2(math.Round(num))
end

local PlayersCol = Color(125, 125, 125, 255)
team.SetUp(1, "No Faction", PlayersCol)

local mults = {
	[HITGROUP_LEFTARM] = 4, [HITGROUP_RIGHTARM] = 4, -- 100% to anywhere on the body
	[HITGROUP_LEFTLEG] = 3, [HITGROUP_RIGHTLEG] = 3, -- 75% to the legs
}

function GM:ScalePlayerDamage(ply, hg, dmg)
	local ret = self.BaseClass.ScalePlayerDamage and self.BaseClass.ScalePlayerDamage(self, ply, hg, dmg)
	if ret then return ret end

	if mults[hg] then
		dmg:ScaleDamage(mults[hg])
	end
end

function GM:PlayerNoClip(ply)

	local Admin = ply:IsAdmin() or ply:IsSuperAdmin()

	if SERVER then
		-- Second argument doesn't work??
		local State = ply:GetMoveType() == MOVETYPE_NOCLIP

		if Admin and ply.AdminPowers == false then
			ply:Notify("You're not in admin mode for noclip. (.admin)", Color(230, 100, 100))
			return false
		end

		if aowl and not Admin and State and not ply.__is_being_physgunned then
			return true
		end
	end

	return game.IsDev() or BaseWars.IsDev(ply) -- and Admin and not ply:InRaid()

end

local function BlockInteraction(ply, ent, ret)

	if ent then

		if not IsValid(ent) then return true end

		local Classes = BaseWars.Config.PhysgunBlockClasses
		if Classes[ent:GetClass()] then return BaseWars.IsDev(ply, ent, ret) end

		local Owner, uid
		if ent.CPPIGetOwner then
			Owner, uid = ent:CPPIGetOwner()
		end

		if IsPlayer(ply) and ply:InRaid() then return BaseWars.IsDev(ply, ent, ret) end
		if IsPlayer(Owner) and Owner:InRaid() then return BaseWars.IsDev(ply, ent, ret) end
		if not IsPlayer(Owner) and uid == CPPI_NOTIMPLEMENTED then
			-- world owner
			return ply:IsAdmin(ply, ent, ret)
		end

	else
		if ply:InRaid() then
			return BaseWars.IsDev(ply, ent, ret)
		end
	end

	return ret == nil or ret

end

local function IsDev(ply, ent, ret)
	if BlockInteraction(ply, ent, ret) == false then return false end

	return BaseWars.IsDev(ply)
end

local function IsAdmin(ply, ent, ret)
	if BlockInteraction(ply, ent, ret) == false then return false end

	return ply:IsAdmin()
end

function GM:PhysgunPickup(ply, ent)
	local Ret = self.BaseClass:PhysgunPickup(ply, ent)

	if ent:IsVehicle() then
		return IsAdmin(ply, ent, Ret)
	end

	return BlockInteraction(ply, ent, Ret)

end

function GM:CanPlayerUnfreeze(ply, ent, phys)
	local Ret = self.BaseClass:CanPlayerUnfreeze(ply, ent, phys)

	return BlockInteraction(ply, ent, Ret)
end

function GM:CanTool(ply, tr, tool)
	local Ret = self.BaseClass:CanTool(ply, tr, tool)

	if BaseWars.Config.BlockedTools[tool] then
		return IsAdmin(ply, ent, Ret)
	end

	if IsValid(tr.Entity) and tr.Entity.IsBaseWars then
		return IsDev(ply, tr.Entity, Ret)
	end

	return BlockInteraction(ply, tr.Entity, Ret)
end

function GM:CanDrive()
	return false
end

function GM:OnPhysgunReload()
	return false
end

function GM:CanProperty(ply, prop, ent, ...)

	local Ret = self.BaseClass:CanProperty(ply, prop, ent, ...)
	local Class = ent:GetClass()

	if prop == "persist" 	then return false end
	if prop == "ignite" 	then return false end
	if prop == "extinguish" then return IsAdmin(ply, ent, Ret) end

	if prop == "remover" and (Class:find("bw_") or ent.IsBaseWars) then return IsAdmin(ply, ent, Ret) end

	return BlockInteraction(ply, ent, Ret)

end

function GM:GravGunPunt(ply, ent)

	local Ret = self.BaseClass:GravGunPunt(ply, ent)
	local Class = ent:GetClass()

	if ent:IsVehicle() then return false end

	if Class == "prop_physics" then return false end

	return BlockInteraction(ply, ent, Ret)

end

local NoSounds = {
	"vo/engineer_no01.mp3",
	"vo/engineer_no02.mp3",
	"vo/engineer_no03.mp3",
}
function GM:PlayerSpawnProp(ply, model)

	local Ret = self.BaseClass:PlayerSpawnProp(ply, model)

	local EscapedModel = model:lower():gsub("\\","/"):gsub("//", "/"):Trim()
	if BaseWars.Config.ModelBlacklist[EscapedModel] then

		ply:EmitSound(NoSounds[math.random(1, #NoSounds)], 140)

	return end

	Ret = (Ret == nil or Ret)

	return Ret == nil or Ret

end

local Lerp = Lerp
local FrameTime = FrameTime
local IsColor = IsColor

local Color = Color

function LC(col, dest, vel)
	local v = 10
	if not IsColor(col) or not IsColor(dest) then return end
	if isnumber(vel) then v = vel end
	local r = Lerp(FrameTime()*v, col.r, dest.r)
	local g = Lerp(FrameTime()*v, col.g, dest.g)
	local b = Lerp(FrameTime()*v, col.b, dest.b)
	return Color(r,g,b)
end

function L(s, d, v, pnl)
	if not v then v = 5 end
	if not s then s = 0 end
	local res = Lerp(FrameTime()*v, s, d)
	if pnl then
		local choose = res>s and "ceil" or "floor"
		res = math[choose](res)
	end
	return res
end