MoarPanelsMats = MoarPanelsMats or {}
MatsBack = MatsBack or {}

setfenv(0, _G) --never speak to me or my son

local math_Round = math.Round
local surface_DrawRect = surface.DrawRect
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_DrawTexturedRectRotated = surface.DrawTexturedRectRotated
local surface_DrawTexturedRectUV = surface.DrawTexturedRectUV
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_SetTextColor = surface.SetTextColor
local surface_SetTextPos = surface.SetTextPos
local surface_DrawText = surface.DrawText
local surface_GetTextSize = surface.GetTextSize
local surface_SetFont = surface.SetFont
local surface_DisableClipping = DisableClipping
local surface_DrawPoly = surface.DrawPoly

MoarPanelsMats.gu = Material("vgui/gradient-u")
MoarPanelsMats.gd = Material("vgui/gradient-d")
MoarPanelsMats.gr = Material("vgui/gradient-r")
MoarPanelsMats.gl = Material("vgui/gradient-l")
MoarPanelsMats.g = Material("gui/gradient", "noclamp smooth")

local sin = math.sin
local cos = math.cos
local mrad = math.rad

local spinner = Material("data/hdl/spinner.png")
local spinner32 = Material("data/hdl/spinner32.png")

local cout = Material("data/hdl/circle_outline256.png")
local cout128 = Material("data/hdl/circle_outline128.png")
local cout64 = Material("data/hdl/circle_outline64.png")

local blur = CreateMaterial("lbu_Blur", "GMODScreenspace", {
	["$basetexture"] = "_rt_FullFrameFB",
	["$texturealpha"] = "0",
	["$vertexalpha"] = "0",
	["$blur"] = 1.6,
})

blur:Recompute()

local _ = spinner:IsError() and hdl.DownloadFile("https://i.imgur.com/KHvsQ4u.png", "spinner.png", function(fn) spinner = Material(fn, "mips") end)
_ = spinner32:IsError() and hdl.DownloadFile("https://i.imgur.com/YMMrRhh.png", "spinner32.png", function(fn) spinner32 = Material(fn, "mips") end)
_ = cout:IsError() and hdl.DownloadFile("https://i.imgur.com/huBY9vo.png", "circle_outline256.png", function(fn) cout = Material(fn, "mips") end)
_ = cout128:IsError() and hdl.DownloadFile("https://i.imgur.com/mLZEMpW.png", "circle_outline128.png", function(fn) cout128 = Material(fn, "mips") end)
_ = cout64:IsError() and hdl.DownloadFile("https://i.imgur.com/kY0Isiz.png", "circle_outline64.png", function(fn) cout64 = Material(fn, "mips") end)


local function LerpColor(frac, into, to, from)

	into.r = Lerp(frac, from.r, to.r)
	into.g = Lerp(frac, from.g, to.g)
	into.b = Lerp(frac, from.b, to.b)

	local sA, c1A, c2A = from.a, into.a, to.a

	if sA ~= c2A or c1A ~= c2A then
		into.a = Lerp(frac, sA, c2A)
	end

end

draw.LerpColor = LerpColor

local function BenchPoly(...)	--shh
	return surface_DrawPoly(...)
end



local sizes = {}

function surface.GetTextSizeQuick(tx, font)
	surface_SetFont(font)
	return surface_GetTextSize(tx)
end

function draw.GetFontHeights(...)
	local ret = {}
	local sum = 0
	for k,v in ipairs({...}) do
		local h = draw.GetFontHeight(v)
		sum = sum + h
		ret[k] = h
	end

	return sum, unpack(ret)
end

function surface.CharSizes(tx, font, unicode)
	local szs = {}
	surface_SetFont(font)
	local cache = sizes[font] or {}
	sizes[font] = cache

	if #tx == 0 then return {} end

	if unicode then
		local codes = {utf8.codepoint(tx, 1, #tx)}
		for i=1, #codes do
			local char = utf8.char(codes[i])
			local sz = cache[char]

			if not sz then
				sz = (surface_GetTextSize(char))
				cache[char] = sz
			end

			szs[i] = sz
		end

	else
		for i=1, #tx do
			local char = tx[i]
			local sz = cache[char]

			if not sz then
				sz = (surface_GetTextSize(char))
				cache[char] = sz
			end

			szs[i] = sz
		end
	end

	return szs
end

local function FetchUpValuePanel()
	return debug.getlocal(3, 1)
end

function draw.LegacyLoading(x, y, w, h)
	local size = math.min(w, h)
	surface_SetMaterial(size < 32 and spinner32 or spinner)
	surface.DrawTexturedRectRotated(x, y, size, size, -(CurTime() * 360) % 360)
end

local tr_vec = Vector()
local sc_vec = Vector()
local vm = Matrix()

function draw.DrawLoading(pnl, x, y, w, h, col)
	local ct = CurTime()
	local sx, sy

	local clipping = true

	if not ispanel(pnl) and pnl ~= nil then 	--backwards compat


		local _, panl = FetchUpValuePanel()

		--shift all vars by 1
		h = w
		w = y
		y = x
		x = pnl

		pnl = panl

		if not ispanel(pnl) then
			draw.LegacyLoading(x, y, w, h)
		return end

		sx, sy = pnl:LocalToScreen(x, y)

	elseif pnl == nil then
		sx, sy = x, y
		x, y = x, y

	elseif ispanel(pnl) then
		sx, sy = pnl:LocalToScreen(x or w/2, y or h/2)
		clipping = false
	end


	w = math.min(w, h)	--smallest square
	h = math.min(w, h)


	local amt = 3
	local dur = 2 --seconds

	if clipping then surface_DisableClipping(true) end

	col = IsColor(col) and col or false
	local r, g, b, mul_a = col and col.r or 255, col and col.g or 255, col and col.b or 255, col and col.a / 255 or 1

	--render.PushFilterMag( TEXFILTER.ANISOTROPIC )
	render.PushFilterMin( TEXFILTER.ANISOTROPIC )

	for i=1, amt do
		local off = dur/amt
		local a = ((ct + off * (i-1)) % dur) / dur

		local rad = w * a
		local mat = (rad > 160 and cout) or (rad > 64 and cout128) or (rad < 64 and cout64) or cout64

		surface_SetMaterial(mat)

		tr_vec[1], tr_vec[2] = sx, sy
		sc_vec[1], sc_vec[2] = a, a

		vm:Reset()
		vm:Translate(tr_vec)
			vm:SetScale(sc_vec)
			tr_vec:Mul(-1)
		vm:Translate(tr_vec)

		cam.PushModelMatrix(vm)
			surface_SetDrawColor(r, g, b, (1 - a) * 255 * mul_a)
			surface_DrawTexturedRect(x - w/2, y - h/2, w, h)
		cam.PopModelMatrix(vm)
	end

	if clipping then surface_DisableClipping(false) end
	render.PopFilterMin()
	--render.PopFilterMag()
end



local rbcache = muldim:new(true)

local function GenerateRBPoly(rad, x, y, w, h, notr, nobr, nobl, notl)


	local deg = 360
	local segdeg = deg / rad / 4

	local lx = x + rad
	local rx = x + w - rad

	local ty = y + rad
	local by = y + h - rad

	local p = {}

	p[1] = {x = x + w/2, y = y + h/2}
	p[2] = {x = lx, y = y}
	p[3] = {x = rx, y = y}

	if not notr then
		for i=1, rad - 1 do
			local a = mrad(segdeg * i)

			local s = sin(a) * rad
			local c = cos(a) * rad

			p[#p + 1] = {
				x = rx + s,
				y = ty - c,
			}
		end
	else
		p[#p+1] = {x = x+w, y = y}
	end

	p[#p + 1] = {x = x+w, y = ty}
	p[#p + 1] = {x = x+w, y = by}

	if not nobr then
		for i=rad, rad*2 - 1 do
			local a = mrad(segdeg * i)
			local s = sin(a) * rad
			local c = cos(a) * rad

			p[#p + 1] = {
				x = rx + s,
				y = by - c,
			}
		end
	else
		p[#p+1] = {x = x+w, y = y+h}
	end

	p[#p + 1] = {x = rx, y = y + h}
	p[#p + 1] = {x = lx, y = y + h}

	if not nobl then
		for i=rad*2, rad*3 - 1 do
			local a = mrad(segdeg * i)
			local s = sin(a) * rad
			local c = cos(a) * rad

			p[#p + 1] = {
				x = lx + s,
				y = by - c,
			}
		end
	else
		p[#p+1] = {x = x, y = y+h}
	end

	p[#p + 1] = {x = x, y = by}
	p[#p + 1] = {x = x, y = ty}

	if not notl then
		for i=rad*3, rad*4 - 1 do
			local a = mrad(segdeg * -i)

			local s = sin(a) * rad
			local c = cos(a) * rad

			p[#p + 1] = {
				x = lx - s,
				y = ty - c,
			}
		end
	else
		p[#p+1] = {x = x, y = y}
	end

	p[#p+1] = {x = lx, y = y}

	return p
end
												--   clockwise order:
												-- V no topright, no bottomright, no bottomleft, no topleft
function draw.RoundedPolyBox(rad, x, y, w, h, col, notr, nobr, nobl, notl)

	--[[
		coords for post-rounded corners
	]]

	surface_SetDrawColor(col:Unpack())
	draw.NoTexture()

	notr = not not notr
	nobr = not not nobr
	nobl = not not nobl
	notl = not not notl

	local cache = rbcache:Get(rad, x, y, w, h, notr, nobr, nobl, notl)

	if not cache then

		local p = GenerateRBPoly(rad, x, y, w, h, notr, nobr, nobl, notl)

		rbcache:Set(p, rad, x, y, w, h, notr, nobr, nobl, notl)
		cache = p
	end

	if not cache then return end
	BenchPoly(cache)
end

local rbexcache = muldim:new(true)

local corners = {
	tex_corner8		= "gui/corner8",
	tex_corner16	= "gui/corner16",
	tex_corner32	= "gui/corner32",
	tex_corner64	= "gui/corner64",
	tex_corner512	= "gui/corner512"
}

draw.AlphatestedCorners = corners

for name, mat in pairs(corners) do
	corners[name] = CreateMaterial("alt05_" .. mat:gsub("gui/", ""), "UnlitGeneric", {
	    ["$basetexture"] = mat,
	    ["$alphatest"] = 1,
	    ["$alphatestreference"] = 0.5,
	    ["$vertexalpha"] = 1,
	    ["$vertexcolor"] = 1
	})
end

function draw.RoundedStencilBox(bordersize, x, y, w, h, col, tl, tr, bl, br)
	if tl == nil then tl = true end
	if tr == nil then tr = true end
	if bl == nil then bl = true end
	if br == nil then br = true end

	if col then surface_SetDrawColor(col:Unpack()) end

	-- Do not waste performance if they don't want rounded corners
	if ( bordersize <= 0 ) then
		surface_DrawRect( x, y, w, h )
		return
	end

	x = math_Round( x )
	y = math_Round( y )
	w = math_Round( w )
	h = math_Round( h )
	bordersize = math.min( math_Round( bordersize ), math.floor( w / 2 ) )

	-- Draw as much of the rect as we can without textures
	surface_DrawRect( x + bordersize, y, w - bordersize * 2, h )
	surface_DrawRect( x, y + bordersize, bordersize, h - bordersize * 2 )
	surface_DrawRect( x + w - bordersize, y + bordersize, bordersize, h - bordersize * 2 )

	local tex = corners.tex_corner8
	if ( bordersize > 8 ) then tex = corners.tex_corner16 end
	if ( bordersize > 16 ) then tex = corners.tex_corner32 end
	if ( bordersize > 32 ) then tex = corners.tex_corner64 end
	if ( bordersize > 64 ) then tex = corners.tex_corner512 end

	surface_SetMaterial( tex )

	if ( tl ) then
		surface_DrawTexturedRectUV( x, y, bordersize, bordersize, 0, 0, 1, 1 )
	else
		surface_DrawRect( x, y, bordersize, bordersize )
	end

	if ( tr ) then
		surface_DrawTexturedRectUV( x + w - bordersize, y, bordersize, bordersize, 1, 0, 0, 1 )
	else
		surface_DrawRect( x + w - bordersize, y, bordersize, bordersize )
	end

	if ( bl ) then
		surface_DrawTexturedRectUV( x, y + h -bordersize, bordersize, bordersize, 0, 1, 1, 0 )
	else
		surface_DrawRect( x, y + h - bordersize, bordersize, bordersize )
	end

	if ( br ) then
		surface_DrawTexturedRectUV( x + w - bordersize, y + h - bordersize, bordersize, bordersize, 1, 1, 0, 0 )
	else
		surface_DrawRect( x + w - bordersize, y + h - bordersize, bordersize, bordersize )
	end
end

local stack = { }

function surface.PushAlphaMult(n)
	stack[#stack + 1] = surface.GetAlphaMultiplier()
	surface.SetAlphaMultiplier(n)
	return stack[#stack]
end

function surface.PopAlphaMult()
	local a = table.remove(stack)
	surface.SetAlphaMultiplier(a)
end

--mostly useful for stencils

--if bottom is true, it'll make the bottom shorter
--otherwise the top is shorter

local poly = {
	{ --[[top left]] },
	{ --[[top right]] },
	{ --[[bottom right]] },
	{ --[[bottom left]] }
}

function draw.RightTrapezoid(x, y, w, h, leg, bottom)
	poly[1].x = x
	poly[1].y = y

	poly[2].x = x + w - (bottom and 0 or leg)
	poly[2].y = y

	poly[3].x = x + w - (bottom and leg or 0)
	poly[3].y = y + h

	poly[4].x = x
	poly[4].y = y + h

	surface.DrawPoly(poly)
end

function draw.RoundedPolyBoxEx(rad, x, y, w, h, col, notr, nobr, nobl, notl)

	surface_SetDrawColor(col)
	draw.NoTexture()

	local cache = rbexcache:Get(rad, x, y, w, h, notr, nobr, nobl, notl)

	if not cache then

		local p = GenerateRBPoly(rad, x, y, w, h, notr, nobr, nobl, notl)

		rbexcache:Set(p, rad, x, y, w, h, notr, nobr, nobl, notl)
		cache = p
	end

	if not cache then return end
	BenchPoly(cache)

end

function draw.ScuffedBlur(pnl, int, x, y, w, h)
	local sx, sy = 0, 0
	if pnl then
		sx, sy = pnl:LocalToScreen(0, 0)
	end
	local sw, sh = ScrW(), ScrH()

	blur:SetFloat("$alpha", int)	-- 0-1 int

	-- SetScissorRect doesn't work with this??
	-- Even if it did, see: https://github.com/Facepunch/garrysmod-issues/issues/4635

	draw.BeginMask()
	render.SetMaterial(blur)
	render.DrawScreenQuadEx(sx, sy, sx + x + w, sy + y + h)

	int = math.max(int, 1)

	draw.DrawOp()

	for i=0, int do
		render.SetMaterial(blur)
		render.UpdateScreenEffectTexture()
		render.DrawScreenQuad()
	end

	draw.FinishMask()

end

function draw.RotatedBox(x, y, x2, y2, w)
	local dx, dy = x2 - x, y2 - y

	draw.NoTexture()

	local rad = -math.atan2(dy, dx)

	local psin = sin(rad) * w
	local pcos = cos(rad) * w

	local poly = {}

		poly[1] = {
			x = x - psin,
			y = y - pcos
		}

		poly[2] = {
			x = x2 - psin,
			y = y2 - pcos,
		}

		poly[3] = {
			x = x2 + psin,
			y = y2 + pcos,
		}

		poly[4] = {
			x = x + psin,
			y = y + pcos,
		}

	surface_DrawPoly(poly)
end

draw.Line = draw.RotatedBox

draw.Rect = surface.DrawRect
draw.DrawRect = surface.DrawRect

draw.Color = surface.SetDrawColor

function White()
	surface.SetDrawColor(255, 255, 255)
end

function surface.DrawMaterial(url, name, x, y, w, h, rot)
	local mat = draw.GetMaterial(url, name)
	if not mat then return false end

	if mat and (mat.downloading or mat.mat:IsError()) then
		draw.DrawLoading(x + w/2, y + h/2, w, h)
		return false
	end

	surface_SetMaterial(mat.mat)

	if rot then
		surface_DrawTexturedRectRotated(x, y, w, h, rot)
	else
		surface_DrawTexturedRect(x, y, w, h)
	end

	return mat
end

function surface.DrawUVMaterial(url, name, x, y, w, h, u1, v1, u2, v2)
	local mat = draw.GetMaterial(url, name .. "(noclamp)", "smooth noclamp ignorez")
	if not mat then return end

	if mat and mat.downloading or not mat.mat or mat.mat:IsError() then
		draw.DrawLoading(x + w/2, y + h/2, w, h)
		return
	end

	surface_SetMaterial(mat.mat)

	surface_DrawTexturedRectUV(x, y, w, h, u1, v1, u2, v2)

end

local shitCircle = CreateMaterial("_crapcircle", "UnlitGeneric", {
	["$basetexture"] = "vgui/circle",
	["$ignorez"] = 1,
	["$translucent"] = 1,

	["$vertexcolor"] = 1,
	["$vertexalpha"] = 1, -- what in the goddamn
})

function draw.SetMaterialCircle(rad)
	local mat

	if rad <= 64 then
		mat = draw.GetMaterial("https://i.imgur.com/MMHZw92.png", "small-circle.png", "smooth ignorez")
	elseif rad <= 256 then
		mat = draw.GetMaterial("https://i.imgur.com/XAWPA15.png", "medium-circle.png", "smooth ignorez")
	else
		mat = draw.GetMaterial("https://i.imgur.com/6SdL8ff.png", "big-circle.png", "smooth ignorez")
	end

	if mat.mat and not mat.mat:IsError() then
		surface.SetMaterial(mat.mat)
	else
		surface.SetMaterial(shitCircle)
	end
end

function draw.DrawMaterialCircle(x, y, rad)	--i hate it but its the only way to make an antialiased circle on clients with no antialiasing set
	if rad <= 64 then
		surface.DrawMaterial("https://i.imgur.com/MMHZw92.png", "small-circle.png", x - rad/2, y - rad/2, rad, rad)
	elseif rad <= 256 then
		surface.DrawMaterial("https://i.imgur.com/XAWPA15.png", "medium-circle.png", x - rad/2, y - rad/2, rad, rad)
	else
		surface.DrawMaterial("https://i.imgur.com/6SdL8ff.png", "big-circle.png", x - rad/2, y - rad/2, rad, rad)
	end
end

draw.MaterialCircle = draw.DrawMaterialCircle

local minstate = 0
local magstate = 0

local anis = TEXFILTER.ANISOTROPIC

local function rep(str)
	return ("	"):rep(minstate) .. str
end

function draw.EnableFilters(min, mag)
	local gm, gmg = min, mag
	if min == nil then
		min = true
	end

	if mag == nil then
		mag = true
	end

	local omin, omag = min, mag

	min = minstate == 0 and min -- if min/mag already enabled, set to false
	mag = magstate == 0 and mag -- otherwise, use original

	minstate = minstate + (omin and 1 or 0)
	magstate = magstate + (omag and 1 or 0)

	if not min and not mag then return end

	--print("+ filters", min, mag)
	if min then render.PushFilterMin(anis) end
	if mag then render.PushFilterMag(anis) end
end

function draw.DisableFilters(min, mag)
	if min == nil then
		min = true
	end

	if mag == nil then
		mag = true
	end

	if minstate == 0 and magstate == 0 then
		ErrorNoHalt("both filters are off")
		return
	end

	local omin, omag = min, mag

	min = minstate == 1 and min -- if min/mag already disabled, set to false (dont need to disable whats disabled)
	mag = magstate == 1 and mag -- otherwise, use original

	minstate = minstate - (omin and 1 or 0)
	magstate = magstate - (omag and 1 or 0)

	if not min and not mag then return end

	--print("- filters", min, mag)
	if mag then render.PopFilterMag() end
	if min then render.PopFilterMin() end
end

hook.Add("PostRender", "ResetFilters", function()
	table.Empty(stack)

	local min, mag

	if minstate > 0 then
		minstate = 1
		min = true
	end

	if magstate > 0 then
		magstate = 1
		mag = true
	end

	if min or mag then
		draw.DisableFilters(min, mag)
		errorf("Leaked filters! Min: %s, mag: %s", min, mag)
	end

end)

function surface.DrawNewlined(tx, x, y, first_x, first_y)
	local i = 0
	local _, th = surface_GetTextSize(tx:gsub("\n", ""))

	for s in tx:gmatch("[^\n]+") do
		surface_SetTextPos(first_x or x, (first_y or y) + i*th)
		surface_DrawText(s)
		i = i + 1

		first_x, first_y = nil, nil
	end

end

function draw.SimpleText2( text, font, x, y, colour, xalign, yalign, addTw, addAl )

	text	= tostring( text )
	x		= x			or 0
	y		= y			or 0
	xalign	= xalign	or TEXT_ALIGN_LEFT
	yalign	= yalign	or TEXT_ALIGN_TOP

	if font then surface_SetFont( font ) end

	local w, h

	if xalign ~= TEXT_ALIGN_LEFT or yalign ~= TEXT_ALIGN_TOP then
		w, h = surface_GetTextSize( text )

		if ( xalign == TEXT_ALIGN_CENTER ) then
			x = x - w / 2
		elseif ( xalign == TEXT_ALIGN_RIGHT ) then
			x = x - w
		end

		if ( yalign == TEXT_ALIGN_CENTER ) then
			y = y - h / 2
		elseif ( yalign == TEXT_ALIGN_BOTTOM ) then
			y = y - h
		end

		x = x - (addTw or 0) * (addAl or xalign) / 2
	end

	surface_SetTextPos(x, y)

	if colour then
		surface_SetTextColor(colour.r, colour.g, colour.b, colour.a)
	--else
		--surface_SetTextColor( 255, 255, 255, 255 )
	end

	surface_DrawText(text)

	return w, h

end

local active = Color(60, 100, 175)
local deactive = Color(75, 75, 75)

local knobactive = Color(110, 170, 245)
local knobdeactive = Color(50, 50, 50)

local cur = Color(0, 0, 0)
local knobcur = Color(0, 0, 0)

function draw.OnOffSlider(fr, x, y, w, h)
	fr = math.Clamp(fr, 0, 1)

	draw.LerpColor(1 - fr, cur, deactive, active)
	draw.LerpColor(1 - fr, knobcur, knobdeactive, knobactive)

	local rnd = math.floor(math.min(h, w) / 2)
	local knob = math.min(h, w)

	local x1 = x + w * 0.05
	local x2 = x + w * 0.95 - knob
	local kx = Lerp(fr, x1, x2) + knob / 2

	draw.RoundedBox(rnd, x + knob / 2, y + math.floor(h / 4), w - knob, h / 2, cur)

	surface.SetDrawColor(knobcur)
	draw.DrawMaterialCircle(kx, y + math.ceil(h / 2), knob)
end