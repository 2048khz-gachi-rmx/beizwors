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

	local modes = {
		{"Wall", "New Wall"},
		{"Mark", "Mark props & ents"},
		{"Enemy", "Create/Edit Enemies"},
		{"Loot", "Create Lootcrate"},
	}

	include("sh_enemy_tool_ext.lua")
	include("sh_loot_tool_ext.lua")


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
end

EndTool()