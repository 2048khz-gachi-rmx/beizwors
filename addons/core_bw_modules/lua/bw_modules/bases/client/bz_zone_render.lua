local bw = BaseWars.Bases

ChainAccessor(bw.Zone, "_ShouldPaint", "ShouldPaint")

function bw.Zone:SetShouldPaint(b)
	if not bw.ZonePaints[self] and not b then return end
	b = b or false

	bw.ZonePaints[self] = b
	self._ShouldPaint = b or false
end

function bw.Zone:UpdatePainted()
	local should = self:Emit("ShouldPaint") -- default is false: never return false or risk breaking shit!
	self:SetShouldPaint(should)
end

function bw.Zone:Draw()
	if bw.Zones[self:GetID()] ~= self then bw.ZonePaints[self] = nil return end

	if self:GetShouldPaint() then
		GlobalAnimatable:MemberLerp(self, "_Alpha", 1, 0.5, 0, 0.3)
	else
		GlobalAnimatable:MemberLerp(self, "_Alpha", 0, 4, 0, 0.3)
	end

	local col = self:GetColor()
	local ca = col.a
	local a = self:GetAlpha()

	-- if we don't draw anymore, remove ourselves from the list
	-- so we don't even bother calling this
	if a == 0 then bw.ZonePaints[self] = nil return end

	local min, max = self:GetBounds()
	if not min or not max then return end --??

	col.a = ca * a -- temporarily modify color alpha then restore it
		render.DrawWireframeBox(vector_origin, angle_zero, min, max, self:GetColor(), false)
	col.a = ca
end



local lastPaintUpdate = CurTime()

hook.Add("PostDrawTranslucentRenderables", "DrawBWZones", function(b, s)
	if b or s then return end
	for k,v in pairs(bw.ZonePaints) do
		k:Draw()
	end

	if CurTime() - lastPaintUpdate > 1 then
		lastPaintUpdate = CurTime()
		for k,v in pairs(bw.Zones) do
			v:UpdatePainted()
		end
	end
end)