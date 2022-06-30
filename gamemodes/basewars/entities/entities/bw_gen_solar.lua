AddCSLuaFile()

ENT.Base 			= "bw_base_generator"
ENT.PrintName 		= "Solar Panel"
ENT.Model 			= "models/props_lab/miniteleport.mdl"
ENT.RenderGroup 	= RENDERGROUP_TRANSLUCENT

ENT.TransmitRadius 	= 200

ENT.PowerGenerated 	= 0
ENT.IsSolarPanel = true
ENT.MaxLevel = 1

BaseWars.Solar = BaseWars.Solar or {}
BaseWars.Solar.SkylessPower = 4
BaseWars.Solar.SkyPower = 10

local skylessPower = BaseWars.Solar.SkylessPower
local skyPower = BaseWars.Solar.SkyPower

function ENT:SHInit()
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
	if CLIENT then
		self.PowerGenerated = self:GetSunAccess() and skyPower or skylessPower
		return
	end
	return BaseWars.Solar.Think(self)
end

local activeCol = Color(235, 180, 70)
local inactiveCol = Color(90, 90, 90)
local txCol = Color(95, 95, 95)

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

function ENT:RateFormat(e)
	return Language("PowerGen", ("%s-%s"):format(
		BaseWars.Solar.SkylessPower, BaseWars.Solar.SkyPower
	))
end

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

local anim
local Frs = {}

local tCol = Color(0, 0, 0)

function ENT:PaintStructureInfo(w, y)
	local add = self:BaseRecurseCall("PaintStructureInfo", w, y)
	y = y + add

	anim = anim or Animatable("SolarDisplay")

	local sun = self:GetSunAccess()
	local base = self:GetBaseAccess()

	local sz = 20
	local col = sun and activeCol or inactiveCol

	local tx = ("Sun access (+%dpw)"):format(skyPower - skylessPower)
	local font = "EXM20"
	local tw, th = surface.GetTextSizeQuick(tx, font)

	local fw = tw + sz + 4

	local eid = self:EntIndex()

	anim:MemberLerp(Frs, eid, sun and 1 or 0, 0.4, 0, math.ease.OutBack)
	local fr = Frs[eid] or 0
	tCol:Lerp(fr, inactiveCol, activeCol)

	surface.SetDrawColor(tCol:Unpack())
	surface.DrawMaterial("https://i.imgur.com/QLZ1kck.png", "sun64.png", w/2 - fw/2, y, sz, sz)

	draw.SimpleText2(tx, nil, w/2 - fw/2 + sz + 4, y + sz / 2 - th * 1.125 / 2, tCol)

	return sz + 2 + add
end