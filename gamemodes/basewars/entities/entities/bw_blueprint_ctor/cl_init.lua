include("shared.lua")
AddCSLuaFile("shared.lua")

function ENT:CLInit()

end

local menu
local col = Color(70, 70, 70, 120)

function ENT:OpenMenu()
	if IsValid(menu) then return end
	local ent = self

	menu = vgui.Create("FFrame")
	menu:SetSize(600, 500)
	menu.Shadow = {}

	menu:MakePopup()
	menu:PopIn()
	menu:CacheShadow(2, 4, 2)

	menu.Inventory = Inventory.Panels.CreateInventory(LocalPlayer().Inventory.Backpack, nil, {
		SlotSize = 64,
		FitsItems = 5
	})

	menu.Inventory:CenterVertical()

	menu:Bind(menu.Inventory)
	menu.Inventory:Bind(menu)

	local inv = menu.Inventory
	inv:SetTall(menu:GetTall())

	local FullW = inv:GetWide() + menu:GetWide()
									--   V inventory has 8px padding from menu
	menu:SetPos(ScrW() / 2 - FullW / 2 - 4, ScrH() / 2 - menu:GetTall() / 2)

	inv:MoveRightOf(menu, 8)
	inv.Y = menu.Y

	local make = self:CreateCreationCanvas(menu, inv)
	local claim = self:CreateClaimCanvas(menu, inv)

	local lastState

	local function selCanv(now)
		local active = ent:GetActive() or ent.Storage.Slots[1] ~= nil or ent:GetHasBP()
		local should = lastState ~= active
		lastState = active

		if not should then return end

		if active then
			make:Disappear(now)
			claim:Appear(now)
		else
			make:Appear(now)
			claim:Disappear(now)
		end
	end

	selCanv(true)

	function menu:Think()
		selCanv()
	end

end

function ENT:Draw()
	self:DrawModel()

	local pos = self:LocalToWorld(Vector(-12, -14, 79))
	local ang = self:GetAngles()

	ang:RotateAroundAxis(ang:Forward(), 90)

	cam.Start3D2D(pos, ang, 0.03)

		local ok, err = pcall(function()
			draw.RoundedBox(8, 0, 0, 750, 650, col)
		end)

	cam.End3D2D()

	if not ok then
		print("err", err)
	end

end

net.Receive("BlueprintConstructor", function()
	local ent = net.ReadEntity()
	if not IsValid(ent) or not ent.BlueprintConstructor then error("wtf " .. tostring(ent)) return end

	ent:OpenMenu()
end)