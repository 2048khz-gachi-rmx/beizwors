setfenv(1, _G)

DarkHUD = DarkHUD or Emitter:callable()

local dh = DarkHUD

--[[------------------------------]]
--	  		Fonts setup
--[[------------------------------]]

DarkHUD.Fonts = DarkHUD.Fonts or {}

local fonts = DarkHUD.Fonts


--[[------------------------------]]
--	  	Used/not used setup
--[[------------------------------]]

DarkHUD.EverUsed = false

sql.Query("CREATE TABLE IF NOT EXISTS DarkHUD(used TEXT, settings TEXT)")
DarkHUD.Used = DarkHUD.Used or {}

local q = sql.Query("SELECT used FROM DarkHUD")

if q and q[1] then
	local t = util.JSONToTable(q[1].used)
	for k,v in pairs(t) do
		DarkHUD.Used[k] = v
	end
end

local used = DarkHUD.Used

if not q then
	sql.Query("INSERT INTO DarkHUD(used, settings) VALUES('[]', '[]')")
end

if used and used[1] and used[1].used then used = util.JSONToTable(used[1].used) end

function DarkHUD.SetUsed(key, val)
	used[key] = val

	local str = SQLStr(util.TableToJSON(used))
	local q = ("UPDATE DarkHUD SET used = %s"):format(str)
	sql.Query(q)
end




--[[------------------------------]]
--	  Scaling & Rescaling setup
--[[------------------------------]]

local scale = 0
DarkHUD.Scale = 0

local log = Logger("DarkHUD", Color(70, 70, 70))


function DarkHUD.ReScale(first)

	if first == true then
		log("First rescaling...")
	else
		log("Resolution changed; rescaling...")
	end

	scale = ScrH() / 1080 * 0.9
	DarkHUD.Scale = scale

	dh.PaddingX = 16 + scale * 36
	dh.PaddingY = 16 + scale * 24

	DarkHUD:Emit("Rescale", scale)
	hook.Run("DarkHUD_Rescaled", scale)
end

DarkHUD.ReScale(true)

--[==================================[
			Settings setup
--]==================================]

local 	st = Settings.Create("darkhud_drawframe", "bool")
			:SetDefaultValue(true)
			:SetCategory("HUD")
			:SetName("Draw HUD background")

DarkHUD.SettingFrame = st


		st = Settings.Create("darkhud_3d", "bool")
			:SetDefaultValue(true)
			:SetCategory("HUD")
			:SetName("Use 3D")

DarkHUD.Setting3D = st




--[==================================[
				Util
--]==================================]
local tex_corner8	= surface.GetTextureID( "gui/corner8" )
local tex_corner16	= surface.GetTextureID( "gui/corner16" )
local tex_corner32	= surface.GetTextureID( "gui/corner32" )

local surface = surface
local corners = draw.AlphatestedCorners

local function RoundedBoxCorneredSize(bordersize, x, y, w, h, color, btl, btr, bbl, bbr, stencil)
	-- the difference is that this has configurable radiuses per-corner

	if w <= 0 or h <= 0 then return end

	surface.SetDrawColor( color.r, color.g, color.b, color.a )

	if ( bordersize <= 0 ) then
		surface.DrawRect( x, y, w, h )
		return
	end

	x = math.floor( x )
	y = math.floor( y )
	w = math.floor( w )
	h = math.floor( h )

	btl = math.min(btl or 0, w)
	bbl = math.min(bbl or 0, w)
	btr = math.min(btr or 0, w - btl)
	bbr = math.min(bbr or 0, w - bbl)

	bordersize = math.min( math.floor( bordersize ), math.floor( w / 2 ) )

	-- Draw as much of the rect as we can without textures

	local rx, ry = x + math.max(btl, bbl), y + math.max(btl, btr)
	local rw, rh = w - (rx - x) - math.max(btr, bbr), h - (ry - y) - math.max(bbl, bbr)

	surface.DrawRect(rx, ry, rw, rh)

	local TbordH = math.max(btl, btr)
	local BbordH = math.max(bbl, bbr)

	-- vertical fill ( |_| )

	--local LbordW = math.max(btl, bbl)
	local RbordW = math.max(btr, bbr)

	if h - bbl - btl > 0 then
		surface.DrawRect( x, y + btl, rx - x, h - bbl - btl ) -- draw left
	end

	if h - btr - bbr > 0 and RbordW > 0 then
		surface.DrawRect( x + w - RbordW, y + btr, RbordW, h - btr - bbr )
	end

	-- horiz fill

	surface.DrawRect(x + btl, y, w - btl - btr, TbordH)
	surface.DrawRect(x + bbl, y + h - BbordH, w - bbl - bbr, BbordH)

	--surface.DrawRect( x, y + btr, RbordW, h - (y + btr) - bbr ) -- draw right

	local tex
	local fn = surface.SetTexture
	if stencil then
		fn = surface.SetMaterial
		tex = corners.tex_corner8
		if ( bordersize > 8 ) then tex = corners.tex_corner16 end
		if ( bordersize > 16 ) then tex = corners.tex_corner32 end
	else
		tex = tex_corner8
		if ( bordersize > 8 ) then tex = tex_corner16 end
		if ( bordersize > 16 ) then tex = tex_corner32 end
	end

	local en = false

	if math.min(btl, btr, bbl, bbr) < 8 then
		draw.EnableFilters()
		en = true
	end

	fn( tex )

	if btl > 0 then
		surface.DrawTexturedRectUV( x, y, btl, btl, 0, 0, 1, 1 )
	end

	if btr > 0 then
		surface.DrawTexturedRectUV( x + w - btr, y, btr, btr, 1, 0, 0, 1 )
	end


	if bbl > 0 then
		surface.DrawTexturedRectUV( x, y + h - bbl, bbl, bbl, 0, 1, 1, 0 )
	end

	if bbr > 0 then
		surface.DrawTexturedRectUV( x + w - bbr, y + h - bbr, bbr, bbr, 1, 1, 0, 0 )
	end

	if en then
		draw.DisableFilters()
	end
end

DarkHUD.RoundedBoxCorneredSize = RoundedBoxCorneredSize


function DarkHUD.PaintBar(rad, x, y, w, h,
	frac, col_empty, col_border, col_main, textData, allow_stencils,
	inverse)

	frac = math.min(frac, 1)

	x = math.ceil(x)
	y = math.ceil(y)
	w = math.ceil(w)
	h = math.ceil(h)

	local bw = math.ceil(w * frac)
	local orig_x = x

	if frac ~= 1 and col_empty then
		draw.RoundedBox(rad, x, y, w, h, col_empty or Colors.Gray)
	end

	if inverse then
		x = x + w - bw
	end

	local stencil = false

	if allow_stencils ~= false then
		if bw < rad * 2 then
			surface.SetDrawColor(255, 255, 255)
			draw.BeginMask()
				surface.DrawRect(x, y, bw, h)
			draw.DrawOp()

			bw = rad * 2
			stencil = true
		elseif istable(textData) then
			draw.BeginMask()

			DarkHUD.RoundedBoxCorneredSize(rad,
				x, y, bw, h,
				color_white, rad, rad, rad, rad, true)

			draw.SetMaskDraw(true)
			--stencil = true
		end
	end


	DarkHUD.RoundedBoxCorneredSize(rad,
		x, y, bw - 1, h,
		col_border or color_white,
		rad, rad, rad, rad, stencil)

	DarkHUD.RoundedBoxCorneredSize(rad,
		x, y + 1, bw, h - 2,
		col_main or Colors.Golden,
		rad, rad, rad, rad, stencil)

	if istable(textData) then

		local fill = textData.Filled or color_white
		local unfill = textData.Unfilled or color_black
		local text = textData.Text or "??"

		local tx, ty = math.floor(orig_x + w / 2), math.floor(y + h / 2)

		draw.DrawOp(1)

		draw.SimpleText(text, textData.Font or "OS20", tx, ty,
			unfill, 1, 1)

		draw.DrawOp(0)

		draw.SimpleText2(text, nil, tx, ty, fill, 1, 1)
	end

	draw.DisableMask()
end

hook.Add("OnScreenSizeChanged", "DarkHUD_Scale", DarkHUD.ReScale)


--[[------------------------------]]
--	    Setup: include files
--[[------------------------------]]

hook.Add("InitPostEntity", "HUDCreate", function()
	DarkHUD:Emit("Ready")
end)

DarkHUD.HideHUDs = DarkHUD.HideHUDs or {}

hook.Add("HUDShouldDraw", "DarkHUD_Hide", function(name)
	if DarkHUD.HideHUDs[name] then return false end
end)

