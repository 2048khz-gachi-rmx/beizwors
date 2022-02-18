include("shared.lua")
AddCSLuaFile("shared.lua")

include("cl_leaderboard.lua")

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:Initialize()

end

local b = bench("Scoreboard", 600)

local bgBord = Color(0, 0, 0)
local bg = Color(30, 30, 30)
local bordSz = 8
local tabSz = 80

local scontr = Color(170, 170, 170)

function BW.Leaderboard.DrawDisplay(self, w, h)
	local st = SysTime()

	bgBord:SetHSV(st * 75, 0.7, 1)

	draw.SetRainbowGradient(true)
	local speed = 0.1

	local v0, v1 = (st * speed) % 1; v1 = v0 + 0.5
	local u0, u1 = (st * speed + 0.5) % 1; u1 = u0 + 0.5

	surface.SetDrawColor(255, 255, 255)
	surface.DrawTexturedRectUV(0, 0, w / 2, h, 0, v1, 1, v0)
	surface.DrawTexturedRectUV(w / 2, 0, w / 2, h, 0, v0, 1, v1)

	draw.SetRainbowGradient()
	surface.DrawTexturedRectUV(bordSz, 0, w - bordSz * 2, h / 2, u0, 0, u1, 1)
	surface.DrawTexturedRectUV(bordSz, h - bordSz, w - bordSz * 2, bordSz, u1, 0, u0, 1)

	surface.SetDrawColor(bg:Unpack())
	surface.DrawRect(bordSz, bordSz, w - bordSz * 2, h - bordSz * 2)

	local xpad = w * 0.15

	surface.SetDrawColor(scontr:Unpack())
	surface.DrawRect(xpad, tabSz, w - xpad * 2, 4)

	--local ypad = th * 0.25
	--BW.Leaderboard.PaintPlayers(self, th + 4 + ypad, w, h, ypad)
end

local depth = -1.6 --[[ 1.6
local depthFar = 3
local farDist = 512
]]

local off = Vector(71, 142.3, depth)

local temp = Vector()


function ENT:GetFrame()
	if not IsValid(self.Frame) then
		local e = self

		local f = vgui.Create("DPanel", self)
		f:SetSize(1423, 711)
		f.Paint = BW.Leaderboard.DrawDisplay

		f:SetPaintedManually(true)
		f:SetMouseInputEnabled(false)

		function f:Think() if not IsValid(e) then self:Remove() end end

		local lb = vgui.Create("BW_LeaderboardCanvas", f)
		self.Frame = f

		f.Tabs = {
			{"Top 10", lb},
			--{"Your Stats", db},
		}

		local ac
		local tw = 0
		local pad = 64

		for k,v in ipairs(f.Tabs) do
			local name, pnl = unpack(v)

			pnl:SetPos(bordSz, bordSz + tabSz)
			pnl:SetSize(f:GetWide() - bordSz * 2, f:GetTall() - pnl.Y - bordSz)

			local btn = vgui.Create("BW_LeaderboardTab", f)
			btn:SetText(name)
			btn:SetTall(tabSz)
			btn:SizeToContents()
			btn.Pnl = pnl

			tw = tw + btn:GetWide() + pad

			btn:On("Activate", "a", function()
				if IsValid(ac) then
					ac:SetActive(false)
					ac.Pnl:PopOutHide()
				end

				ac = btn
				pnl:PopInShow()
			end)

			v[3] = btn

			if k == 1 then
				btn:SetActive(true)
			else
				pnl:Hide()
			end
		end

		tw = tw - pad

		local nx = (f:GetWide() - bordSz * 2) / 2 - tw / 2

		for k,v in ipairs(f.Tabs) do
			v[3]:SetPos(nx, bordSz)
			nx = nx + v[3]:GetWide() + pad
		end
	end

	return self.Frame
end

function ENT:Draw()
	--self:DrawModel()

	local f = self:GetFrame()

	--b:Open()
	local pos = self:LocalToWorld(off)
	local ang = self:GetAngles()

	ang:RotateAroundAxis(ang:ToUp(temp), -90)

	vgui.Start3D2D(pos, ang, 0.2)
		f:Paint3D2D()
	vgui.End3D2D()

	--[[cam.Start3D2D(pos, ang, 0.2)
		xpcall(self.DrawDisplay, GenerateErrorer("LeaderboardDisplay"), self)
	cam.End3D2D()]]
	--b:Close():print()
end

for k,v in ipairs(ents.FindByClass("bw_leaderboard")) do
	if IsValid(v.Frame) then v.Frame:Remove() end
end