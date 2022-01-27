local AV = {}

local err = Material("__error")

function AV:Init()
	self.Rounding = 16
end

function AV:StencilAvatar(w, h)
	surface.SetDrawColor(255, 255, 255)
	--surface.DrawRect(0, 0, w, h)
	draw.NoTexture()
	draw.RoundedStencilBox(self.Rounding, 0, 0, w, h, color_white)
end


function AV:Paint(w, h)
	--draw.BeginMask(self.StencilAvatar, self, w, h)
	--draw.DrawOp()

	--[[local x, y = self:LocalToScreen(0, 0)
	self._w, self._h = self:GetSize()
	self:SetSize(512, 512)

	draw.EnableMaskCircle(0, 0, 512, 512)]]
	surface.PushAlphaMult(9999)
	self:Emit("Paint", w, h)
	draw.BeginMask(self.StencilAvatar, self, w, h)
	draw.DrawOp()
	surface.PopAlphaMult()
end

function AV:PaintOver(w, h)

	--draw.DisableMaskCircle(0, 0, h)
	--self:SetSize(self._w, self._h)
	self:Emit("PreDemaskPaint", w, h)
	draw.FinishMask()
	self:Emit("PaintOver", w, h)
end

vgui.Register("CircularAvatar", AV, "AvatarImage")

