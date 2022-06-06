local col = Color(0, 0, 0)

function EFFECT:Init( data )
	self.origin = data:GetOrigin()
	self.norm = data:GetNormal()

	self.CT = CurTime()
	self.Length = 3

	local em = ParticleEmitter(self.origin)

	local spreadNorm = Vector(self.norm)
	local orig = Vector(self.origin)

	for i=0, 8 do
		local v = i % 2 == 0 and 0.2 or 0.5
		col:SetHSV(31, 0.35, v)
		spreadNorm:AngleSpread(math.Rand(0, 0.8), math.Rand(0, 1.4))
		--debugoverlay.Line(pos, pos + spreadNorm * 500, 1, color_white)
		spreadNorm:Mul(-4)
		orig:Add(spreadNorm)
		spreadNorm:Mul(-math.Rand(19, 27) * 2)

		local smoke = em:Add("particle/smokesprites_000" .. math.random(1, 9), orig)
		if smoke then
			smoke:SetVelocity(spreadNorm)
			smoke:SetDieTime(math.Rand(0.5, 1.3))
			smoke:SetStartAlpha(math.Rand(40, 60))
			smoke:SetEndAlpha(0)
			smoke:SetStartSize(5)
			smoke:SetEndSize(16)
			smoke:SetRoll(math.Rand(240, 360))
			smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			smoke:SetAirResistance(500)
			smoke:SetColor(col:Unpack())
		end

		spreadNorm:Set(self.norm)
		orig:Set(self.origin)
	end
	em:Finish()
end

function EFFECT:GetExistTime()
	return CurTime() - self.CT
end

function EFFECT:Think()
	local left = self.Length - (CurTime() - self.CT)

	local needExist = left > 0

	return needExist
end

function EFFECT:Render() end