local TOOL = AIBases.LayoutTool

local opts = {"NoTarget"}
local acOpts = {}
local ct = 1
local curWep = "random"


function TOOL:Opt_EnemyLeftClick(tr)
	local ent = tr.Entity
	if IsValid(ent) and ent.IsAIBaseBot then
		sfx.Failure()
		print("NYI")
		return
	end

	net.Start("aib_layout")
		net.WriteUInt(1, 4)
		net.WriteVector(tr.HitPos)
		net.WriteBool(not not acOpts.NoTarget)
		net.WriteString(curWep)
		net.WriteUInt(ct, 8)
	net.SendToServer()
end

function TOOL:Opt_SelectEnemy(f)
	if IsValid(self.spotHolder) then
		self.spotHolder.Y = f.ModeHolder.Y + f.ModeHolder:GetTall() + 8 + 32
		self.spotHolder:MoveTo(0, f.ModeHolder.Y + f.ModeHolder:GetTall() + 8, 0.3, 0, 0.3)
		self.spotHolder:PopInShow()
		return
	end

	local canv = vgui.Create("InvisPanel", f)
	canv:SetSize(f:GetWide(), f:GetTall())
	canv:SetPos(0, f.ModeHolder.Y + f.ModeHolder:GetTall() + 8 + 32)
	canv.WillY = f.ModeHolder.Y + f.ModeHolder:GetTall() + 8
	canv:MoveTo(0, canv.WillY, 0.3, 0, 0.3)
	canv:PopIn()
	self.spotHolder = canv

	local spotHolder = vgui.Create("InvisPanel", canv)
	spotHolder:SetSize(f:GetWide(), 32)
	spotHolder:SetPos(0, 0)

	local spotBtns = {}

	local spotW = (f:GetWide() / 2 - 16 - (table.Count(opts) - 1) * 4) / table.Count(opts)
	local x = 8

	for k,v in pairs(opts) do
		local btn = vgui.Create("FButton", spotHolder)
		spotBtns[v] = btn

		btn:SetSize(spotW, 32)
		btn:SetPos(x, 0)
		btn:SetText(v)
		btn:SetFont("OS20")

		x = x + spotW + 4

		function btn:DoClick()
			self.Active = not self.Active
			self:SetColor(self.Active and Colors.Sky or Colors.Button)
			acOpts[v] = self.Active and true or nil
		end

		if acOpts[v] then
			btn.Active = true
			btn:SetColor(btn.Active and Colors.Sky or Colors.Button)
		end
	end

	x = x + 8
	local lX = x

	local lbl = vgui.Create("DLabel", spotHolder)
	lbl:SetText("Weapon:")
	lbl:SetPos(x)
	lbl:SetFont("OSB24")
	lbl:SizeToContents()
	lbl:CenterVertical()
	x = x + lbl:GetWide() + 4

	local te = vgui.Create("FTextEntry", spotHolder)
	te:SetPlaceholderText("random")
	if curWep ~= "random" then
		te:SetText(curWep)
	end
	te:SetPos(x)
	te:SetSize(spotHolder:GetWide() - x - 4, spotHolder:GetTall())

	local focused = false

	te:On("GetFocus", function()
		f:SetKeyBoardInputEnabled(true)
		AIBases.Builder.LayoutBind:SetHeld(true)
		focused = true
	end)

	te:On("LoseFocus", function()
		f:SetKeyBoardInputEnabled(false)
		focused = false
	end)


	function te:Think()

		local blank = self:GetText() == ""
		local wep = not blank and weapons.GetStored(self:GetText())

		if not blank and not wep and not AIBases.WeaponPools[self:GetText()] then
			local bad = Colors.DarkerRed
			te:LerpColor(te.TextColor, bad, 0.1, 0, 0.2)

			bad = Color(75, 40, 40)
				te:LerpColor(te.BGColor, bad, 0.1, 0, 0.2)

			bad = Color(170, 80, 80)
				te:LerpColor(te.HTextColor, bad, 0.1, 0, 0.2)
		else
			local regular = color_white
			te:LerpColor(te.TextColor, regular, 0.1, 0, 0.2)

			regular = Color(40, 40, 40)
			te:LerpColor(te.BGColor, regular, 0.1, 0, 0.2)

			regular = Colors.LighterGray
			te:LerpColor(te.HTextColor, regular, 0.1, 0, 0.2)
			curWep = blank and "random" or self:GetText()
		end

		if not focused then
			AIBases.Builder.LayoutBind:SetHeld(false)
		end
	end

	AIBases.Builder.LayoutBind:On("ButtonChanged", te, function(self, to)
		if to == true and not focused then
			self:SetHeld(false)
		end
	end)

	local w = canv:GetWide() - lX - 4
	local bw = (w - 4 * 2) / 3

	for i=1, 3 do
		local btn = vgui.Create("FButton", canv)
		btn:SetPos(lX, spotHolder:GetTall() + 4)
		btn:SetSize(bw, 32)
		btn:SetText("Tier " .. i)
		lX = lX + btn:GetWide() + 4

		function btn:Think()
			if ct == i then
				self:SetColor(Colors.Sky)
			else
				self:SetColor(Colors.Button)
			end
		end

		function btn:DoClick()
			ct = i
		end
	end
end

function TOOL:Opt_DeselectEnemy(f)
	if IsValid(self.spotHolder) then
		self.spotHolder:MoveBy(0, 24, 0.3, 0, 0.3)
		self.spotHolder:PopOutHide()
	end
end

TOOL:Update()