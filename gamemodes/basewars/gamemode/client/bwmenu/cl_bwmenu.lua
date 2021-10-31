--[[
	tabData = {
		[1] = onOpenFunction,
		[2] = onCloseFunction,
		[3] = onCreatedButtonFunction,
			
		Order = [number], (bigger = created sooner)
		IsDefault = true/false,

		+ 	any additional key/values you want; they'll be transferred onto the tab button
			and you can access them by doing `btn.TabData`
	}
]]
BaseWars.Menu = BaseWars.Menu or {
	Tabs = {},

	Frame = nil, --will be a panel

	Fonts = {}
}

if IsValid(BaseWars.Menu.Frame) then BaseWars.Menu.Frame:Remove() end

local PopoutTime = 0
local fonts = BaseWars.Menu.Fonts

function BaseWars.Menu.ReScale()

	local scale = math.max(ScrH() / 1080 * 0.4 + 0.6, ScrH() / 1080)	-- 60% is the minimum size, the other 40% is influenced by scale
																		-- i can't say much about higher resolutions, doing this blindly p much
	fonts.Sizes = fonts.Sizes or {}
	local sz = fonts.Sizes

	-- sizes
	sz.Big = 20 + 16 * scale
	sz.MediumBig = 16 + 16 * scale
	sz.Medium = 10 + 16 * scale
	sz.MediumSmall = 10 + 12 * scale
	sz.Small = 8 + 12 * scale
	sz.Small = 6 + 12 * scale

	local family = "Open Sans Regular"

	for k,v in pairs(sz) do
		local fn = "BWMenu_" .. k
		surface.CreateFont(fn, {
			font = family,
			size = v
		})

		fonts[k] = fn
	end


	-- bolds

	fonts.BoldSizes = fonts.BoldSizes or {}
	local bsz = fonts.BoldSizes

	bsz.Small = 8 + 16 * scale
	bsz.Tiny = 6 + 12 * scale
	bsz.Medium = 16 + 12 * scale
	bsz.Big = 24 + 16 * scale

	BaseWars.Menu.Scale = scale

	family = "BreezeSans Medium"

	for k,v in pairs(bsz) do
		local fn = "BWMenu_Bold" .. k
		surface.CreateFont(fn, {
			font = family,
			size = v
		})

		fonts["Bold" .. k] = fn
	end

	for k,v in pairs(bsz) do
		local fn = "BWMenu_Blur" .. k
		surface.CreateFont(fn, {
			font = family,
			size = v,
			blursize = 8
		})

		fonts["Blur" .. k] = fn
	end

end

BaseWars.Menu.ReScale()

hook.Add("OnScreenSizeChanged", "BWMenuScale", BaseWars.Menu.ReScale)

local function CreateBWFrame()
	local f = vgui.Create("NavFrame")

	BaseWars.Menu.Frame = f

	f.Scale = BaseWars.Menu.Scale
	local sc = f.Scale
	f:SetSize(sc * 700, sc * 500)
	f:CacheShadow(3, 2, 2)
	f:Center()
	f:MakePopup()
	f.Shadow = {}

	f:PopIn()
	f:SetRetractedSize(f:GetRetractedSize() * 1.2)
	function f:Disappear()
		self:PopOutHide(nil, nil, function()
			PopoutTime = CurTime()
		end)

		self:SetMouseInputEnabled(false)
		self:SetKeyboardInputEnabled(false)

		self:Emit("Disappear")
	end
	
	function f:Appear()
		self:PopInShow()
		self:SetMouseInputEnabled(true)
		self:SetKeyboardInputEnabled(true)
	end

	function f:OnKeyCodePressed(key)
		if key == KEY_F3 then
			self:Disappear()
		end
	end

	local sorted = {}	--[[ [seq_num] = { tabName, order, tabData } ]]

	for name, tabData in pairs(BaseWars.Menu.Tabs) do
		sorted[#sorted + 1] = {name, tabData.Order or 0, tabData}
	end

	table.sort(sorted, function(a, b)
		return a[2] > b[2]
	end)

	for _, data in ipairs(sorted) do

--[[	{
			[1] = "Name",
			[2] = order_number,
			[3] = {
				openFunc,
				closeFunc,
				createTabFunc
			}
		}	]]

		local name = data[1]
		local tabData = data[3]

		local tab = f:AddTab(name, tabData[1], tabData[2])
		tab.TabData = tabData


		if tabData[3] then
			tabData[3] (f, tab)
		end

		if tabData.IsDefault then
			f:SelectTab(name, true)
		end
	end
end

hook.Add("PlayerButtonDown", "BaseWarsMenu", function(ply, btn)
	if btn ~= KEY_F3 then return end
	if not IsFirstTimePredicted() then return end

	local wep = LocalPlayer():GetActiveWeapon()
	if wep ~= NULL and wep.CW20Weapon and wep.dt.State == (CW_CUSTOMIZE or 4) then return end

	if math.abs(PopoutTime - CurTime()) <= 0.1 then return end

	if IsValid(BaseWars.Menu.Frame) then
		if not BaseWars.Menu.Frame:IsVisible() then
			BaseWars.Menu.Frame:Appear()
		end

		return
	end

	CreateBWFrame()

end)

concommand.Add("openBWMenu", function()
	if IsValid(BaseWars.Menu.Frame) then return end
	if math.abs(PopoutTime - CurTime()) <= 0.1 then return end

	CreateBWFrame()
end)

include("cl_factions_mainframe_ext.lua")

include("cl_factions_ext.lua")
include("cl_raids_ext.lua")
include("cl_settings_ext.lua")