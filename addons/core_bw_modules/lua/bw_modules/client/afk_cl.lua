--

local PLAYER = debug.getregistry().Player
BaseWars.AFK = BaseWars.AFK or {}
local AFK = BaseWars.AFK

local lastNet = CurTime()

function AFK.ClearAFK()
	local ply = LocalPlayer()

	if not ply:IsAFK() or lastNet < 2 then
		return
	end

	if CurTime() - lastNet > 1 then
		net.Start("AFK")
			net.WriteUInt(AFK.CLEAR, 2)
		net.SendToServer()
		lastNet = CurTime()

		hook.Run("AFKExit", LocalPlayer())
	end

	AFK.UnlimitFPS()
end

PLAYER.ClearAFK = AFK.ClearAFK

local trans = Color(255, 255, 255)
local green = Color(120, 210, 120)
local shade = Color(0, 0, 0, 250)

surface.CreateFont("AFKTimeBlur", {
	font = "Roboto Condensed",
	size = 48,
	blursize = 6,
	weight = 600,
})

surface.CreateFont("AFKTime", {
	font = "Roboto Condensed",
	size = 48,
	weight = 600,
})

local ta = 0
local gone = 0
local back = 0
local col = trans:Copy()
local time = 0

function MODULE.Paint()
	local ply = LocalPlayer()

	if not ply:IsAFK() then
		if back == 0 and gone ~= 0 then
			back = CurTime()
			gone = 0
		end

		if CurTime() - back < 1.5 then
			LC(col, green)
		elseif ta > 1 then

			ta = L(ta, 0, 20)

			if ta<=1 then
				back = 0
				col:Set(trans)
			end
		end
	else
		gone = CurTime()
		time = ply:AFKTime()
		ta = L(ta, 255, 3)
	end

	local AFKTime = string.TimeParse(time)
	local str = "You have been AFK for"

	shade.a = ta
	col.a = ta

	draw.SimpleText(str, "AFKTimeBlur", ScrW()/2+1, ScrH()/4+1, shade, 1, 1)
	draw.SimpleText(str, "AFKTime", ScrW()/2, ScrH()/4, col, 1, 1)

	draw.SimpleText(AFKTime, "AFKTimeBlur", ScrW()/2+1, ScrH()/4+53, shade, 1, 1)
	draw.SimpleText(AFKTime, "AFKTime", ScrW()/2, ScrH()/4+52, col, 1, 1)
end

hook.Add("HUDPaint", "PaintAFK", MODULE.Paint)

local fps_while_afk = 30

--[[
local need_render = false
local last_render = 0
local delay = 1 / fps_while_afk
]]

local fps_cvar = GetConVar("fps_max")

local afk_cvar = CreateConVar("_bw_afk_fps_limited_DONTTOUCHME", "0", FCVAR_ARCHIVE,
	"This convar is used to track your FPS when it gets limited by the AFK power saver.\n" ..
	"You probably shouldn't touch this...")

local base = AFK.BaseMaxFPS or fps_cvar:GetInt()
AFK.BaseMaxFPS = base
AFK.FPSLimited = (AFK.FPSLimited ~= nil and AFK.FPSLimited) or false

function AFK.LimitFPS()
	if fps_cvar:GetInt() == fps_while_afk then return end

	base = fps_cvar:GetInt()
	afk_cvar:SetInt(base)

	AFK.BaseMaxFPS = base

	RunConsoleCommand("fps_max", fps_while_afk)
	AFK.FPSLimited = true
end

function AFK.UnlimitFPS()
	if not AFK.FPSLimited then return end

	afk_cvar:SetInt(0)
	RunConsoleCommand("fps_max", AFK.BaseMaxFPS)
	AFK.FPSLimited = false
end

function AFK.SendFocus(b)
	net.Start("AFK")
		net.WriteUInt(AFK.FOCUS, 2)
		net.WriteBool(b)
	net.SendToServer()
end


if afk_cvar:GetInt() > 30 then
	print("settings fps max to preserved")

	AFK.FPSLimited = true
	AFK.BaseMaxFPS = afk_cvar:GetInt()

	AFK.UnlimitFPS()
end


hook.Add("RenderScene", "AFKSave", function()
	local me = LocalPlayer()
	if not me:IsValid() then return end

	if me:IsAFK() and me:AFKTime() > BaseWars.Config.AFKConserveTime then
		AFK.LimitFPS()

		--[[local passed = SysTime() - last_render
		if passed > delay then
			need_render = true
			last_render = SysTime()
		else
			return true
		end]]
	elseif not me:IsAFK() then
		AFK.UnlimitFPS()
	end
end)


hook.Add("AFKExit", "AFK_FPS", function()
	AFK.UnlimitFPS()
end)
