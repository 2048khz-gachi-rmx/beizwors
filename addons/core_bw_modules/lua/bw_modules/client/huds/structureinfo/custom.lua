local hud = BaseWars.HUD
local sin = hud.StructureInfo
local anim = sin.Anims

function sin:PaintCustom(cury)
	local ent = self:GetEntity():IsValid() and self:GetEntity()
	local w, h = self:GetSize()

	local toW, retH = w, 0

	if ent and ent.PaintStructureInfo then
		local needHeight, needWidth = ent:PaintStructureInfo(w, cury)

		if not needHeight then
			print("reminder: ENT:PaintStructureInfo needs to return additional height. return 0 if unnecessary.")
			needHeight = 0
		end

		if ent then
			-- only add the info height if we're actually looking at the ent rn
			retH = retH + needHeight
			if needWidth then
				toW = math.max(w, needWidth)
			end
		end
	end

	self:SetWide(toW)

	return retH
end

sin.AddPaintOp(10, "PaintCustom", sin)

