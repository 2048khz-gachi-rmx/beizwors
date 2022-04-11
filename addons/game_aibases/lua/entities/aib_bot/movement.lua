function ENT:DoWander()
	local cnav = navmesh.GetNearestNavArea(self:GetPos(), false, 500, false, true)

	self:StartActivity( ACT_WALK )
	self.loco:SetDesiredSpeed( 95 )

	if cnav:IsValid() then
		for i=1, 10 do
			if self:TryMovePos(cnav:GetRandomPoint()) then break end
		end
	end

	self:StartActivity( ACT_IDLE )
end

local trIn, trOut = {}, {}
trIn.output = trOut

function ENT:TryMovePos(pos)
	pos[3] = pos[3] + 8
	local min, max = self:GetCollisionBounds()

	trIn.mins = min
	trIn.maxs = max
	trIn.start = pos
	trIn.endpos = Vector(pos)
	trIn.filter = self

	util.TraceHull(trIn)

	if trOut.Hit then
		debugoverlay.SweptBox(trIn.start, trIn.endpos, trIn.mins, trIn.maxs, angle_zero, 4, Colors.Red)
		return false
	else
		debugoverlay.SweptBox(trIn.start, trIn.endpos, trIn.mins, trIn.maxs, angle_zero, 4, color_white)
		self:MoveToPos(pos)
		return true
	end
end