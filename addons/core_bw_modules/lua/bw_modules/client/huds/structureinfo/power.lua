local hud = BaseWars.HUD
local sin = hud.StructureInfo
local anim = sin.Anims

local col = Color(100, 80, 80)

function sin:PaintPower(cury)
	local ent = self:GetEntity():IsValid() and self:GetEntity()
	local w, h = self:GetSize()

	local noPwTo = ent and
		(not ent.IsPowered or ent:IsPowered()) and 0
		or 1

	local pwFr = self.NoPWFrac or noPwTo
	self.NoPWFrac = pwFr


	if ent then
		anim:MemberLerp(self, "NoPWFrac", noPwTo, 0.3, 0, 0.3)
	end

	pwFr = self.NoPWFrac or pwFr

	local offy = cury

	local szTo = 0

	if pwFr > 0 then
		offy = offy - draw.GetFontHeight("OSB20") * 0.25 * pwFr -- wtf
		surface.SetDrawColor(255, 255, 255)

		draw.BeginMask(surface.DrawRect, 0, cury, w, h)
		draw.DrawOp()

		col.r = 220 + math.sin(CurTime() * math.pi * 3) * 30
		col.a = 255 * pwFr

		local _, th = draw.SimpleText("No power!", "OSB20",
			w / 2, offy, col, 1, 5)

		--th = th + 4
		offy = offy + math.ceil(th * pwFr)
		szTo = th * noPwTo

		draw.DisableMask()
	end

	return offy - cury, szTo
end

sin.AddPaintOp(9000, "PaintPower", sin)