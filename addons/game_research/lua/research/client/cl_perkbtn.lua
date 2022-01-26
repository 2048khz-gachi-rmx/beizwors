--

local PERK = {}

function PERK:Init()
	self:SetText("")
end

local bg = Color(62, 62, 62)

function PERK:Paint(w, h)
	self:HoverLogic(self:GetDisabled(), w, h)

	bg:SetDraw()
	draw.DrawMaterialCircle(w / 2, h / 2, h)

	if self.Icon then
		self.Icon:Paint(w / 2, h / 2, w * 0.65, h * 0.65)
	end
end

function PERK:SetLevel(level)
	local ic = level:GetIcon()
	if ic then
		self.Icon = ic:Copy()
		self.Icon:SetAlignment(5)
	end

	self.Perk = level
	self.Level = level
end

function PERK:Deselect()
	if not self.Selected then return end
	print("deselect")
	self.Selected = false
	self:Emit("Deselect", self.Perk)
end

function PERK:Select()
	if self.Selected then return end
	print("select")
	self.Selected = true
	self:Emit("Select", self.Perk)
end

function PERK:DoClick()
	print("click")
	if not self.Selected then
		self:Select()
	else
		self:Deselect()
	end
end

vgui.Register("ResearchPerk", PERK, "FButton")