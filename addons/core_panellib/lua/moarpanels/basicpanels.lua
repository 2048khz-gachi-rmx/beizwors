
local gu = Material("vgui/gradient-u")
local gd = Material("vgui/gradient-d")
local gr = Material("vgui/gradient-r")
local gl = Material("vgui/gradient-l")

CreateLogID("MPMatrices", "leaked %d matrices: %s", {0, ""})

function LC(col, dest, vel)
	local v = vel or 10
	if not IsColor(col) or not IsColor(dest) then return end

	col.r = Lerp(FrameTime() * v, col.r, dest.r)
	col.g = Lerp(FrameTime() * v, col.g, dest.g)
	col.b = Lerp(FrameTime() * v, col.b, dest.b)

	if dest.a ~= col.a then
		col.a = Lerp(FrameTime() * v, col.a, dest.a)
	end

	return col
end

function LCC(col, r, g, b, a, vel)
	local v = vel or 10

	col.r = Lerp(FrameTime() * v, col.r, r)
	col.g = Lerp(FrameTime() * v, col.g, g)
	col.b = Lerp(FrameTime() * v, col.b, b)

	if a and a ~= col.a then
		col.a = Lerp(FrameTime() * v, col.a, a)
	end

	return col
end

function L(s,d,v,pnl)
	if not v then v = 5 end
	if not s then s = 0 end
	local res = Lerp(FrameTime() * v, s, d)

	if pnl then
		local choose = (res > s and "ceil") or "floor"
		res = math[choose](res)
	end

	return res
end

Colors = Colors or {}

Fonts = Fonts or {}

--[[
	TODO: delete fonts that you don't use
	cuz as of 04.05 it's 19x15 = 285 fonts
]]


local families = {
	["Roboto"] = "R",
	["Roboto Light"] = "RL",

	["Titillium Web"] = "TW",
	["Titillium Web SemiBold"] = "TWB",

	["Open Sans"] = "OS",
	["Open Sans SemiBold"] = "OSB",
	["Open Sans Light"] = "OSL",

	["Arial"] = "A",
	["Helvetica"] = "HL",

	["Montserrat"] = "MR",
	["Montserrat Medium"] = "MRM",
	["Montserrat Bold"] = "MRB",

	["SnareDrum Zero NBP"] = "SDZ",
	["SnareDrum Two NBP"] = "SDT",

	["BreezeSans"] = "BS",
	["BreezeSans Medium"] = "BSSB",
	["BreezeSans Light"] = "BSL",
	["BreezeSans Bold"] = "BSB",

	["DejaVu Sans"] = "DV",

	["Sydnie"] = "SYD"
}

FontFamilies = families

local sizes = {12, 14, 16, 18, 20, 22, 24, 28, 32, 36, 44, 48, 56, 64, 72, 96, 128}

for k,v in pairs(families) do

	for _, size in pairs(sizes) do
		if not Fonts[v .. size] then
			surface.CreateFont(v .. size, {
				font = k,
				size = size,
				weight = 400,
			})

			Fonts[v .. size] = k
		end
	end

end

Emitter.HookPaint = function(what)
	if not what.Paint then
		what.Paint = function(self, ...)
			self:Emit("Paint", ...)
		end
	end

	if not what.Think then
		what.Think = function(self, ...)
			self:Emit("Think", ...)
		end
	end

end

function vgui.ToPrePostPaint(tbl)
	tbl.PrePaint = tbl.PrePaint or BlankFunc
	tbl.Draw = tbl.Draw or BlankFunc
	tbl.PostPaint = tbl.PostPaint or BlankFunc

	function tbl:Paint(w, h)
		self:PrePaint(w, h)
		self:Draw(w, h)
		self:PostPaint(w, h)
		self:Emit("Paint", w, h)
	end
end

-- only works with fonts made above ^
function Fonts.PickFont(fam, txt, wid, hgt, start_size)
	start_size = start_size or 128
	hgt = hgt or wid

	local picked = fam .. start_size

	for i=#sizes, 1, -1 do
		local sz = sizes[i]

		if sz > start_size then continue end

		surface.SetFont(fam .. sz)
		local tw = surface.GetTextSize(txt)

		if tw <= wid and sz < hgt then
			return fam .. sz, sz
		end
	end

	return picked, sz
end

function Fonts.ClosestSize(h)
	for i=#sizes, 1, -1 do
		if sizes[i] <= h then
			return sizes[i]
		end
	end
end

function vgui.ColorSetters(t)

	function t:SetColor(col, g, b, a)
		if IsColor(col) then
			self.Color:Set(col)
			if g then 	--if 2nd arg, that means apply now
				self.drawColor = col:Copy()
			end
			return
		end

		local c = self.Color
		c.r = col or 70
		c.g = g or 70
		c.b = b or 70
		c.a = a or 255
	end

	function t:GetColor()
		return self.Color
	end

	function t:GetDrawColor()
		return self.drawColor
	end
end

local active

function vgui.GetActiveTextEntry()
	return active
end

hook.Add("OnTextEntryGetFocus", "vgui_GetActiveTextEntry", function(pnl)
	active = pnl
end)

hook.Add("OnTextEntryLoseFocus", "vgui_GetActiveTextEntry", function(pnl)
	if active == pnl then active = nil end
end)

concommand.Add("ColorPicker", function()
	local f = vgui.Create("FFrame")
	f:SetSize(500, 400)
	f:Center()
	f.Shadow = {}
	f:MakePopup()
	f:PopIn()
	f:AddDockPadding(16, 0, 16, 0)

	local col = vgui.Create("DColorMixer", f)
	col:Dock(FILL)
	col:DockMargin(40, 0, 40, 8)

	function col:ValueChanged(col)
		f.HeaderColor = col
		self:Emit("C", col)
	end

	local cpy = vgui.Create("InvisPanel", f)
	local txt = vgui.Create("FTextEntry", cpy)
	local cpybtn = vgui.Create("FButton", cpy)

	cpy:SetTall(40)
	cpy:Dock(BOTTOM)

	txt:SetWide(300)
	txt:Dock(FILL)
	txt:DockMargin(4, 4, 4, 4)
	txt:SetContentAlignment(5)

	col:On("C", function(_, c)
		cpybtn:SetColor(c.r, c.g, c.b, c.a or 255)
		local s = "Color(%d, %d, %d%s)"
		txt:SetValue(
			s:format(c.r, c.g, c.b, (c.a and c.a ~= 255 and ", " .. c.a) or "")
		)
	end)

	cpybtn:SetWide(120)
	cpybtn:Dock(LEFT)
	cpybtn:DockMargin(8, 4, 4, 4)
	cpybtn.Label = "Copy"

	function cpybtn:DoClick()
		SetClipboardText(txt:GetValue())
	end
end)