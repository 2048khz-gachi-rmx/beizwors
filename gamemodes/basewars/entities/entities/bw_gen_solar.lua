AddCSLuaFile()

ENT.Base 			= "bw_base_generator"
ENT.PrintName 		= "Solar Panel"
ENT.Model 			= "models/props_lab/miniteleport.mdl"

ENT.TransmitRadius 	= 200

ENT.PowerGenerated 	= 0
ENT.IsSolarPanel = true

BaseWars.Solar = BaseWars.Solar or {}
BaseWars.Solar.SkylessPower = 4
BaseWars.Solar.SkyPower = 10

local skylessPower = BaseWars.Solar.SkylessPower
local skyPower = BaseWars.Solar.SkyPower

function ENT:Init()
	if CLIENT then return end
	BaseWars.Solar.Initialize(self)
	self.PowerGenerated = 0
end

function ENT:DerivedGenDataTables()
	self:NetworkVar("Bool", 3, "SunAccess")
	self:NetworkVar("Bool", 4, "BaseAccess")
end

function ENT:Think()
	self.BaseClass.Think(self)
	if CLIENT then return end
	return BaseWars.Solar.Think(self)
end

function ENT:GenerateOptions(qm, pnl)
	local ind = vgui.Create("GradPanel", pnl)
	ind:SetSize(80, 72)
	ind:Center()
	ind.Color = Colors.DarkGray
	ind.Y = ind.Y + pnl.CircleSize + 8

	if qm.SunIndicator and qm.SunIndicator:IsValid() then error("Retard") end
	qm.SunIndicator = ind
	local ent = self
	local sz = 32

	local tx = "%d%%"
	local pwtx = "( %dpw/s )"

	local activeCol = Color(235, 180, 70)
	local inactiveCol = Color(60, 60, 60)
	local txCol = Color(95, 95, 95)

	local sun = ent:GetSunAccess()
	local base = ent:GetBaseAccess()

	local eff_perc = skylessPower / skyPower

	local eff = base and (sun and 100 or eff_perc) or 0
	ind.Efficiency = eff

	local boxCol = Color(30, 30, 30, 250)

	ind:On("Paint", "Solar", function(self, w, h)
		sun = ent:GetSunAccess()
		base = ent:GetBaseAccess()
		eff = base and (sun and 100 or eff_perc * 100) or 0

		self:To("Efficiency", eff, 0.3, 0, 0.3)

		eff = math.Round(self.Efficiency)

		local col = sun and activeCol or inactiveCol
		surface.SetDrawColor(col:Unpack())
		surface.DrawMaterial("https://i.imgur.com/QLZ1kck.png", "sun64.png", w/2 - sz/2, 2, sz, sz)
		local tx = tx:format(eff)
		local pwtx = pwtx:format( math.Round( skyPower * (self.Efficiency / 100)) )
		local _, tH = draw.SimpleText(tx, "OS24", w/2, 2 + sz - (24 * 0.125), color_white, 1, 5)
		draw.SimpleText(pwtx, "OS18", w/2, 2 + sz - (24 * 0.3) + tH, txCol, 1, 5)

		if not base then
			local tx = "Solar panel output doesn't reach base!"
			surface.SetFont("OSB24")
			local tw, th = surface.GetTextSize(tx)
			DisableClipping(true)
				draw.RoundedBox(4, w / 2 - tw / 2 - 4, h + 2, tw + 8, th + 4, boxCol)
				draw.SimpleText(tx, "OSB24",
					w / 2 - tw / 2, h + 4, Colors.DarkerRed, 0, 5)
			DisableClipping(false)
		end
	end)


	qm:AddPopIn(ind, ind.X, ind.Y, 0, ind:GetTall() / 2)
	return ind
end

local rayPos = Vector(2.4543991088867, -32.136005401611, 3.2566497325897)
local ray = Material("trails/physbeam")

function ENT:Draw()
	self:DrawModel()
	local qm = self.IsQMInteracting
	self._LastInteract = qm and CurTime() or self._LastInteract or 0

	if qm or CurTime() - self._LastInteract < 5 then
		local pos = self:LocalToWorld(rayPos)
		local pos2 = pos + self:GetAngles():Up() * 16384

		render.SetMaterial(ray)
		render.DrawBeam(pos, pos2, 8, 0, 1, color_white)
		-- draw a beam from sun scanner pos
	end
end
