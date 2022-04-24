AIBases.Builder = AIBases.Builder or {}
local bld = AIBases.Builder
bld.NW = bld.NW or Networkable("aibuild")

bld.Tracker = bld.Tracker or muldim:new()
bld.EntTracker = bld.EntTracker or muldim:new()

StartTool("AIBaseBuild")

TOOL.Name = "[sadmin] BaseBuild"
TOOL.Category = "AIBases"

AIBases.LayoutTool = TOOL
local TOOL = AIBases.LayoutTool
TOOL.LayoutTool = true
TOOL.CurMode = _LAYCURMODE

if SERVER then
	util.AddNetworkString("aib_layout")
end

function bld.Allowed(ply)
	if not IsValid(ply) then return false end
	if not BaseWars.IsDev(ply) and not ply.CAN_USE_AIBASE and not game.IsDev() then return false end

	return true
end

function TOOL:Allowed()
	local p = self:GetOwner()
	if not bld.Allowed(p) then return false end

	return true
end

local function setEnum(ow, e, id)
	assert(IsPlayer(ow))
	assert(isnumber(id) or id == nil)

	local elist = bld.Tracker:GetOrSet(ow)
	elist[e] = id

	local plylist = bld.EntTracker:GetOrSet(e)
	plylist[ow] = true

	bld.NW[ow:UserID()] = bld.NW[ow:UserID()] or {}
	bld.NW[ow:UserID()][e] = id
	bld.NW:SetTable(ow:UserID(), bld.NW[ow:UserID()])
end

AIBases.Builder.AddBrick = setEnum

function TOOL:LeftClick(tr)
	if SERVER or not IsFirstTimePredicted() then return end

	if self.CurMode then
		local name = self.CurMode[1]
		if not self["Opt_" .. name .. "LeftClick"] then
			printf("No method: %s", "Opt_" .. name .. "LeftClick")
			return
		end

		self["Opt_" .. name .. "LeftClick"] (self, tr)
	end
end

--[[function TOOL:LeftClick(tr)
	if not IsFirstTimePredicted() then return end

	local e = tr.Entity
	if not IsValid(e) then return end

	local ow = self:GetOwner()
	if not self:Allowed() then return end

	setEnum(ow, e, AIBases.BRICK_PROP)
end]]

function TOOL:Reload(tr)
	--[[if not IsFirstTimePredicted() then return end

	local e = tr.Entity
	if not IsValid(e) then return end

	local ow = self:GetOwner()
	if not self:Allowed() then return end

	setEnum(ow, e, AIBases.BRICK_BOX)]]
end

function TOOL:RightClick(tr)
	--[[if not IsFirstTimePredicted() then return end

	local e = tr.Entity
	if not IsValid(e) then return end

	local ow = self:GetOwner()

	local elist = bld.Tracker:GetOrSet(ow)
	elist[e] = nil

	local plylist = bld.EntTracker:GetOrSet(e)
	plylist[ow] = nil

	bld.NW[ow:UserID()] = bld.NW[ow:UserID()] or {}
	bld.NW[ow:UserID()][e] = nil
	bld.NW:SetTable(ow:UserID(), bld.NW[ow:UserID()])]]
	if SERVER or not IsFirstTimePredicted() then return end

	if self.CurMode then
		local name = self.CurMode[1]
		if not self["Opt_" .. name .. "RightClick"] then
			printf("No method: %s", "Opt_" .. name .. "RightClick")
			return
		end

		self["Opt_" .. name .. "RightClick"] (self, tr)
	end
end

function TOOL:GetList()
	return bld.Tracker:GetOrSet(self:GetOwner())
end


if CLIENT then

	local opts = {"NoTarget"}
	local acOpts = {}
	local ct = 1
	local curWep = "random"

	local modes = {
		{"Wall", "New Wall"},
		{"Mark", "Mark props & ents"},
		{"Enemy", "Create/Edit Enemies"},
	}

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

	function TOOL:Opt_MarkLeftClick(tr)
		local ent = tr.Entity
		if not IsValid(ent) then
			sfx.Failure()
			return
		end

		local props = bld.NW:Get(LocalPlayer():UserID())
		if props and props[ent] then
			net.Start("aib_layout")
				net.WriteUInt(0, 4)
				net.WriteEntity(ent)
				net.WriteUInt(15, 4)
			net.SendToServer()
			return
		end

		net.Start("aib_layout")
			net.WriteUInt(0, 4)
			net.WriteEntity(ent)
			net.WriteUInt(AIBases.BRICK_PROP, 4)
		net.SendToServer()

		sfx.CheckIn()
	end

	function TOOL:Opt_MarkRightClick(tr)
		local ent = tr.Entity
		if not IsValid(ent) then
			sfx.Failure()
			return
		end

		local props = bld.NW:Get(LocalPlayer():UserID())
		if props and props[ent] then
			net.Start("aib_layout")
				net.WriteUInt(0, 4)
				net.WriteEntity(ent)
				net.WriteUInt(15, 4)
			net.SendToServer()
			return
		end

		net.Start("aib_layout")
			net.WriteUInt(0, 4)
			net.WriteEntity(ent)
			net.WriteUInt(AIBases.BRICK_BOX, 4)
		net.SendToServer()

		sfx.CheckIn()
	end

	function TOOL:Opt_WallLeftClick()
		local am = GetTool("AreaMark", LocalPlayer())
		RunConsoleCommand("gmod_tool", "AreaMark")
		local pr = am:JustMark()
		pr:Then(function(self, _, ...)
			RunConsoleCommand("gmod_tool", "AIBaseBuild")
			hook.Run("AIBuildArea", ...)
		end, function()
			RunConsoleCommand("gmod_tool", "AIBaseBuild")
		end)
	end

	function TOOL:ShowOptions(dat)
		if IsValid(dat[1]) then
			dat[1]:Remove()
		end

		local tool = self
		local f = vgui.Create("FFrame")
		dat[1] = f
		dat[2] = self

		f:SetSize(ScrW() * 0.4, ScrH() * 0.25)
		f:CenterHorizontal()
		f.Y = ScrH()
		f:MoveTo(f.X, ScrH() - f:GetTall() - 32, 0.2, 0, 0.3)
		f:SetMouseInputEnabled(true)
		f:MakePopup()
		f:SetKeyboardInputEnabled(false)
		f:PopIn()
		RestoreCursorPosition()

		function f:PrePaint()
			DisableClipping(true)
				surface.SetDrawColor(0, 0, 0, 180)
				surface.DrawRect(-ScrW(), -ScrH(), ScrW() * 2, ScrH() * 2)
			DisableClipping(false)
		end

		local modeHolder = vgui.Create("InvisPanel", f)
		modeHolder:SetSize(f:GetWide(), 32)
		modeHolder:SetPos(4, f.HeaderSize + 4)
		f.ModeHolder = modeHolder

		local modeBtns = {}
		local ac = false
		local x = 8
		local modeW = (f:GetWide() - 16 - (table.Count(modes) - 1) * 8) / table.Count(modes)

		for k,v in pairs(modes) do
			local btn = vgui.Create("FButton", modeHolder)
			modeBtns[k] = btn

			btn:SetSize(modeW, 32)
			btn:SetPos(x, 0)
			btn:SetText(v[2])
			btn:SetFont("OSB20")

			x = x + modeW + 8

			function btn:DoClick()
				if self.Active then return end

				if ac then
					ac:Deselect()
				end

				self.Active = true
				self:SetColor(self.Active and Colors.Sky or Colors.Button)
				tool.CurMode = v
				_LAYCURMODE = v
				ac = self

				if tool["Opt_Select" .. v[1]] then
					tool["Opt_Select" .. v[1]] (tool, f)
				end
			end

			function btn:Deselect()
				if not self.Active then return end

				self.Active = false
				self:SetColor(self.Active and Colors.Sky or Colors.Button)
				if tool["Opt_Deselect" .. v[1]] then
					tool["Opt_Deselect" .. v[1]] (tool, f)
				end
			end

			if tool.CurMode and tool.CurMode[1] == v[1] then btn:DoClick() end
		end
	end

	function TOOL:HideOptions(dat)
		if not IsValid(dat[1]) then return end
		local f = dat[1]
		f:PopOut(0.2)
		f:MoveTo(f.X, ScrH(), 0.2, 0, 3.3, function()
			f:Remove()
		end)

		RememberCursorPosition()
		f:SetMouseInputEnabled(false)

		dat[1] = nil
	end

	function TOOL:GetInstance()
		local lp = LocalPlayer()
		if not lp or not lp:IsValid() then return false end

		local tool = lp:GetTool()
		local wep = tool and tool:GetWeapon()
		if not tool or not tool.LayoutTool or lp:GetActiveWeapon() ~= wep then return false end

		return tool
	end

	local curTool = AIBases.Builder.LayMenus or {} -- { pnl, tool }
	AIBases.Builder.LayMenus = curTool

	if IsValid(curTool[1]) then curTool[1]:Remove() end

	local bnd = Bind("aib_layout")
	bnd:SetHeld(false)
	AIBases.Builder.LayoutBind = bnd

	local MENU_KEY = KEY_R

	bnd:SetDefaultKey(MENU_KEY)
	bnd:SetKey(MENU_KEY)
	bnd:SetDefaultMethod(BINDS_HOLD)
	bnd:SetMethod(BINDS_HOLD)

	bnd:On("Activate", 1, function(self, ply)
		local tool = TOOL:GetInstance()
		if not tool then return end
		tool:ShowOptions(curTool)
	end)

	bnd:On("Deactivate", 1, function(self, ply)
		if not curTool[2] then return end
		curTool[2]:HideOptions(curTool)
	end)
else
	net.Receive("aib_layout", function(len, ply)
		if not bld.Allowed(ply) then return end

		local mode = net.ReadUInt(4)

		if mode == 0 then
			-- mark
			local ent = net.ReadEntity()
			local how = net.ReadUInt(4)

			if how == 15 then
				how = nil
			else
				if ent.IsAIBaseBot then how = AIBases.BRICK_ENEMY end
				if ent.IsMorphDoor then how = AIBases.BRICK_DOOR end
			end

			setEnum(ply, ent, how)
		elseif mode == 1 then
			local where = net.ReadVector()

			local en = ents.Create("aib_bot")

			en.NoTarget = net.ReadBool()
			local wepClass = net.ReadString()
			local tier = net.ReadUInt(8)

			en:SetPos(where)
			en.ForceWeapon = wepClass
			en.Tier = tier

			local ang = (ply:EyePos() - where):Angle()
			ang.p = 0
			en:SetAngles(ang)

			en:Spawn()
			en:Activate()

			undo.Create("ai bot")
				undo.SetPlayer(ply)
				undo.AddEntity(en)
			undo.Finish("ai bot")

			en.debug = true
			_G.bot = en
		end
	end)
end

EndTool()