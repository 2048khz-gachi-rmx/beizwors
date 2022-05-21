local TOOL = AIBases.LayoutTool

local allOpts = {
	LibItUp.Selection({"scrap", "wepcrate"}, "scrap"),
	LibItUp.Selection({"low", "mid (NYI)"}, "low"),
	LibItUp.Selection({"small", "medium (NYI)"}, "small"),
}

local curLootMdl = "models/props/CS_militia/footlocker01_closed.mdl"

function TOOL:Opt_LootLeftClick(tr)
	local ent = tr.Entity
	if IsValid(ent) then
		sfx.Failure()
		CLP():PopupNotify(NOTIFY_ERROR, "not implemented", 1)
		return
	end

	net.Start("aib_layout")
		net.WriteUInt(2, 4)
		net.WriteVector(tr.HitPos)
		net.WriteString(curLootMdl)
		net.WriteString(("%s_%s_%s"):format(allOpts[1]:Get(), allOpts[2]:Get(), allOpts[3]:Get()))
	net.SendToServer()
end

function TOOL:Opt_SelectLoot(f)
	if IsValid(self.lootHolder) then
		self.lootHolder.Y = f.ModeHolder.Y + f.ModeHolder:GetTall() + 8 + 32
		self.lootHolder:MoveTo(0, f.ModeHolder.Y + f.ModeHolder:GetTall() + 8, 0.3, 0, 0.3)
		self.lootHolder:PopInShow()
		return
	end

	local canv = vgui.Create("InvisPanel", f)
	canv:SetSize(f:GetWide(), f:GetTall())
	canv:SetPos(0, f.ModeHolder.Y + f.ModeHolder:GetTall() + 8 + 32)
	canv.WillY = f.ModeHolder.Y + f.ModeHolder:GetTall() + 8
	canv:MoveTo(0, canv.WillY, 0.3, 0, 0.3)
	canv:PopIn()
	self.lootHolder = canv

	local lootHolder = vgui.Create("InvisPanel", canv)
	lootHolder:SetSize(f:GetWide(), 28)
	lootHolder:SetPos(0, 0)

	for i, sel in pairs(allOpts) do
		local hld = vgui.Create("InvisPanel", canv)
		hld.Y = lootHolder.Y + lootHolder:GetTall() + 4 + 36 * (i - 1)
		hld:SetSize(f:GetWide(), 32)

		local pad = 8
		local optW = (f:GetWide() / 2 - 16 - (table.Count(sel:GetOptions()) - 1) * pad) / table.Count(sel:GetOptions())
		local x = f:GetWide() / 2 - ((optW + pad) * #sel:GetOptions() - pad) / 2

		for oi, opt in pairs(sel:GetOptions()) do
			local btn = vgui.Create("FButton", hld)

			btn:SetSize(optW, 32)
			btn:SetPos(x, 0)
			btn:SetText(opt)
			btn:SetFont("OS20")

			x = x + optW + pad

			function btn:DoClick()
				sel:Select(opt)
			end

			function btn:Upd()
				self.Active = sel:Selected(opt)
				self:SetColor(self.Active and Colors.Sky or Colors.Button)
			end

			sel:On("Selected", btn, function(...) btn:Upd() end)
			btn:Upd()
		end
	end

	local lX = 8

	local lbl = vgui.Create("DLabel", lootHolder)
	lbl:SetText("Model:")
	lbl:SetPos(lX)
	lbl:SetFont("OSB24")
	lbl:SizeToContents()
	lbl:CenterVertical()
	lX = lX + lbl:GetWide() + 4

	local te = vgui.Create("FTextEntry", lootHolder)
	te:SetPlaceholderText("models/props/CS_militia/footlocker01_closed.mdl")
	if curLootMdl ~= te:GetPlaceholderText() then
		te:SetText(curLootMdl)
	end

	te:SetPos(lX)
	te:SetSize(lootHolder:GetWide() - lX - 4, lootHolder:GetTall())

	local focused = false

	te:On("GetFocus", function()
		f:SetKeyboardInputEnabled(true)
		AIBases.Builder.LayoutBind:SetHeld(true)
		focused = true
		print("focus yes")
	end)

	te:On("LoseFocus", function()
		f:SetKeyboardInputEnabled(false)
		focused = false
		print("no focus")
	end)

	function te:OnRemove() self:Emit("LoseFocus") end

	local exCache = {}

	function te:Think()
		local blank = self:GetText() == ""
		local tx = self:GetText()
		local wep = not blank and weapons.GetStored(tx)

		exCache[tx] = Either(exCache[tx] ~= nil, exCache[tx], file.Exists(tx, "GAME"))

		if not blank and not exCache[tx] then
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
			curLootMdl = blank and self:GetPlaceholderText() or tx
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
end

function TOOL:Opt_DeselectLoot(f)
	if IsValid(self.lootHolder) then
		self.lootHolder:MoveBy(0, 24, 0.3, 0, 0.3)
		self.lootHolder:PopOut()
	end
end

TOOL:Update()