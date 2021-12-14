AddCSLuaFile()

ENT.Base 			= "bw_base_generator"
ENT.PrintName 		= "Manual Generator"

ENT.Model 			= "models/props_c17/cashregister01a.mdl"

ENT.PowerGenerated 	= 0

ENT.Sounds 			= {Sound("physics/flesh/flesh_squishy_impact_hard1.wav"), Sound("physics/flesh/flesh_squishy_impact_hard2.wav"), Sound("physics/flesh/flesh_squishy_impact_hard3.wav"), Sound("physics/flesh/flesh_squishy_impact_hard4.wav")}
ENT.Color			= Color(0, 0, 0, 255)

ENT.IsManualGen 	= true
ENT.MaxLevel = 1

if SERVER then util.AddNetworkString("ManualGen") end

local powerGen = 12

function ENT:Init(...)
	self.BaseClass.Init(self, ...)

	--[[self.PowerGenerated2 = math.floor(
		math.ceil(2 * 4 / BaseWars.Bases.PowerGrid.ThinkInterval) / 10
	) * 10]]
	self.PowerGenerated2 = powerGen
end

function ENT:RateFormat()
	return Language("PowerGenManual", powerGen)
end

function ENT:GenPower()

	self:EmitSound(self.Sounds[math.random(1, #self.Sounds)])

	local grid = self:GetPowerGrid()
	if not grid then return end

	self:GetPowerGrid():AddPower(self.PowerGenerated2)
end

function ENT:GenerateOptions(qm, pnl)
	if not self.PowerGenerated2 then self:Init() end
	local gen = vgui.Create("FButton", pnl)
	gen:SetLabel("Make power")

	gen:SetSize(160, 48)

	gen:Center()

	gen.AlwaysDrawShadow = true

	gen:PopIn()
	gen:SetDoubleClickingEnabled(false)
	gen:SetMouseInputEnabled(true)

	gen.DoClick = function()
		net.Start("ManualGen")
			net.WriteEntity(self)
		net.SendToServer()

		local grid = self:GetPowerGrid()
		if not grid then return end

		local nw = self:GetPowerGrid():GetNW()

		grid:AddPower(self.PowerGenerated2)

		local ent = self

		--if not grid.ManualTapped then
			nw:On("NetworkedChanged", self, function(self)

			end)
		--end
	end

	local pw = vgui.Create("InvisPanel", pnl)

	pw:SetSize(200, 40)

	pw:Center()
	pw.Y = pw.Y + pnl.CircleSize

	local w, h = pw:GetContentSize()
	local ent = self

	local notbase = Color(180, 50, 50)
	local pwcol = Color(50, 160, 250)

	function pw:Paint(w, h)
		if not IsValid(ent) then pnl:Remove() return end
		surface.SetDrawColor(60, 60, 60, 150)
		surface.DrawRect(0, 0, w, h)

		local grid = ent:GetPowerGrid()
		local base = LocalPlayer():GetBase()

		if base and grid and base:GetPowerGrid() == grid then
			draw.SimpleText(("Power: %d/%d"):format(grid:GetPower(), grid:GetCapacity()),
				"OSB24", w/2, h/2, pwcol, 1, 1)
		else
			draw.SimpleText("Not in your base.", "OSB24", w/2, h/2, notbase, 1, 1)
		end

		surface.SetDrawColor(0, 0, 0)
		self:DrawGradientBorder(w, h, 3, 3)

	end

	qm:AddPopIn(pw, pw.X, pw.Y, 0, 32)
	qm:AddPopIn(gen, gen.X, gen.Y - pnl.CircleSize - 8, 0, -32)

	return gen, pw
end

if SERVER then
	net.Receive("ManualGen", function(_, ply)
		local gen = net.ReadEntity()

		if not IsValid(gen) or not gen.IsManualGen then return end
		if ply:GetPos():Distance(gen:GetPos()) > 196 then return end

		gen:GenPower()
	end)
end