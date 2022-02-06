local bw = BaseWars.Bases
bw.HUD = bw.HUD or Emitter()
local hud = bw.HUD

local ptr = BaseWars.HUD.Painter:extend()

hud.Anims = hud.Anims or Animatable("base_anims")
hud.ActivePainters = hud.ActivePainters or {} 	-- [seqid] = painter
hud.BaseToPaint = hud.BaseToPaint or {}		-- [baseid] = painter
hud.MaxY = hud.MaxY or 0
hud.PaintOps = hud.PaintOps or {}

function ptr:_GenMatrix(mx)
	local infr, outfr = self.AppearFrac, self.DisappearFrac

	local cx = Lerp(infr, self.AppearFromX, self.AppearToX)
	local cy = Lerp(infr, self.AppearFromY - self:GetTall(), self.AppearToY)

	cx = Lerp(outfr, cx, self.DisappearToX - self:GetWide())
	cy = Lerp(outfr, cy, self.DisappearToY)

	mx:TranslateNumber(cx, cy)
	self.TranslateY = cy
end

ChainAccessor(ptr, "_Base", "Base")

function ptr:Delete()
	table.RemoveByValue(hud.ActivePainters, self)
	local base = self:GetBase()

	if hud.BaseToPaint[base] == self then
		hud.BaseToPaint[base] = nil
	end
end

function ptr:Initialize(base)
	assert(bw.IsBase(base))

	self._Base = base
	hud.BaseToPaint[base] = self

	table.insert(hud.ActivePainters, self)
end

function hud.CreateBasePainter(base)
	local p = ptr:new(base)
	p:FillPainters(hud.PaintOps)
	return
end

function hud.GetBasePainter(base)
	if not hud.BaseToPaint[base] then
		hud.CreateBasePainter(base)
	end

	return hud.BaseToPaint[base]
end

function hud.AddPaintOp(prio, name, tbl)
	if (not tbl or not tbl[name]) and not ptr[name] then
		errorf("ptr:AddPaint() : tbl.%s and ptr.%s didn't exist.", name, name)
		return
	end

	for k,v in pairs(hud.BaseToPaint) do
		v:AddPaint(prio, name, tbl)
	end

	hud.PaintOps[name] = {tbl, prio}
end


function hud.RestartPainters()
	table.Empty(hud.ActivePainters)
	table.Empty(hud.BaseToPaint)
end

function hud.DoPainters(base, zone)
	local ptr = base and hud.GetBasePainter(base)

	if base then
		ptr:Appear()
	end

	hud.MaxY = 0

	for i=#hud.ActivePainters, 1, -1 do
		local ptr = hud.ActivePainters[i]
		if ptr:GetBase() ~= base then
			ptr:Disappear()
		end
		local y = ptr:Paint()
		hud.MaxY = math.max(hud.MaxY, y)
	end
end

hud.RestartPainters()

FInc.FromHere("*.lua", FInc.CLIENT, FInc.RealmResolver():SetDefault(true))