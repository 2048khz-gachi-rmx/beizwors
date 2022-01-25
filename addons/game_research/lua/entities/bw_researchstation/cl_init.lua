--soon:tm:
AddCSLuaFile()
include("shared.lua")

function ENT:DrawDisplay()

end

function ENT:OpenMenu()
	local trees = Research.GetTrees()

	local f = vgui.Create("NavFrame")
	f:SetSize(900, 600)
	f:Center()

	f:MakePopup()
	f:PopIn()

	local canv = vgui.Create("ResearchMap", f)
	f:PositionPanel(canv)

	f.Navbar.ShowHolder:SetTall(f.ExpandHeight + 4)
	canv.SearchPanel:SetTall(f.ExpandHeight - 4)

	canv:Populate()

	for k,v in pairs(trees) do
		f:AddTab(v:GetName(), function(...)
			canv:SetTree(v)
		end)
	end
end

local off = Vector(63.65, 16.1, -4.6)

function ENT:Draw()
	self:DrawModel()

	local pos = self:LocalToWorld(off)
	local ang = self:GetAngles()

	ang:RotateAroundAxis(ang:Up(), 90)
	ang:RotateAroundAxis(ang:Forward(), 90)

	cam.Start3D2D(pos, ang, 0.05)
		xpcall(self.DrawDisplay, GenerateErrorer("ResearchStationRender"), self)
	cam.End3D2D()
end

net.Receive("ResearchComputer", function()
	local comp = net.ReadEntity()
	if not IsValid(comp) or not comp.ResearchComputer then return end
	comp:OpenMenu()
end)