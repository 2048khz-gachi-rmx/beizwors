function ENT:DoWander()
	local cnav = navmesh.GetNearestNavArea(self:GetPos(), false, 200, false, true)

	if cnav:IsValid() then
		for i=1, 10 do
			if self:TryMovePos(cnav:GetRandomPoint()) then break end
		end
	end

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
		--debugoverlay.SweptBox(trIn.start, trIn.endpos, trIn.mins, trIn.maxs, angle_zero, 4, Colors.Red)
		return false
	else
		--debugoverlay.SweptBox(trIn.start, trIn.endpos, trIn.mins, trIn.maxs, angle_zero, 4, color_white)
		--self:MoveToPos(pos)
		self:MoveWhenCan(pos)
		return true
	end
end

function ENT:C_MoveNow(pos)
	-- yield and return whether we moved successfully or were interrupted
	self.WantMoveWhere = pos
	local coro = coroutine.running()

	if self._movePr then
		self._movePr:Reject()
		self._movePr = nil
	end

	self._mvNowCoro = coro
	self._movePr = Promise()

	local status

	self._movePr:Then(function()
		status = true
	end, function()
		status = false
	end)

	while status == nil do
		coroutine.yield()
	end

	return status
end

function ENT:MoveWhenCan(pos)
	-- non-coroutine request to move somewhere
	self.WantMoveWhere = pos

	print("movewhencan", pos)
	if self._movePr then
		self._movePr:Reject()
	end

	self._movePr = Promise()
	return self._movePr
end

function ENT:DoQueuedMove()
	-- called from behavior coro
	local p = self.WantMoveWhere
	if not p then return end

	self:StartActivity(ACT_RUN)

	self.loco:SetDesiredSpeed(self.MoveSpeed)

	self.WantMoveWhere = nil
	self:MoveToPos(p)
	self:StartActivity(self:GetDesiredActivity())

	if self._movePr then
		self._movePr:Resolve()
		self._movePr = nil
	end
	--self:DoQueuedMove(pos)
end

function ENT:WantReload(tac)
	local wep = self:GetCurrentWeapon()

	if wep:Clip1() < wep:GetMaxClip1() * (tac and 0.75 or 0.3) then
		return true
	end

	return false
end

function ENT:TakeCover()
	local spot = self:FindSpot("near")
	if not spot then return false end

	local pr = self:MoveWhenCan(spot)
	return pr
end

-- try to get to a place where sightOf is visible
function ENT:TryChase(sightOf)
	--[[local t = {
		pos = self:GetPos(),
		radius = 192,
	}

	local have_cover = self:FindSpot("random", t)

	t.pos = sightOf
	local will_have = self:FindSpot("random", t)

	if will_have or not have_cover then]]
		self:C_MoveNow(sightOf)
		self:HaveEnemy()
		self:UpdateTargetLOS()

		if self:GetEnemy() and not self:CanSeeTarget() then
			self:LoseEnemy()

			local cnav = navmesh.GetNavArea(self:GetPos(), 4)
			if not IsValid(cnav) then return end
			self:SetAimingAt(cnav:GetCenter())
		end
	--end
end

function ENT:ShouldChase(time, sightOf)
	if time < 4 then return false end
	if self:HasActivity("Reload") then return false end
	if self:GetPos():Distance(sightOf) < 8 then return false end
	if not self:GetEnemy() then return false end

	-- todo: camping?

	return true
end

function ENT:DecideMovement()
	if self.TargetAligned or self.TrackingEnemy then
		-- we have an enemy,

		-- but we cant see them right now; piss off to cover and reload if needed
		local can, time = self:CanSeeTarget()
		if self:WantReload(true) and not can and time > 0.6 + math.random() then
			self:RequestReload(false)
			return
		end
	end

	local en = self:GetEnemy()
	local can, time, lastPos = self:CanSeeTarget()

	if en and not can and self:ShouldChase(time, lastPos) then
		self:TryChase(lastPos)
	end

end

function ENT:MoveToPos( pos, options )
	options = options or {}

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 20 )
	path:Compute( self, pos, self:GetPathGenerator() )

	if ( !path:IsValid() ) then return "failed" end

	while ( path:IsValid() ) do

		path:Update( self )

		if self.debug then
			local cur = path:GetCurrentGoal()
			local seg = path:GetAllSegments()

			if seg then
				local isnext = true
				for k,v in pairs(seg) do
					local iscur = cur and cur.pos:IsEqualTol(v.pos, 1)
					if iscur then isnext = false end

					local col = iscur and Colors.Sky or isnext and Colors.LighterGray or Colors.Money
					debugoverlay.Sphere(v.pos, 4, 0.2, col, true)
					debugoverlay.Line(v.pos, v.pos - v.forward * 16, 0.2, Colors.Sky, true)
					debugoverlay.Text(v.pos + Vector(0, 0, 8),
						("%d: %s"):format(k, tostring(IsValid(v.area) and v.area:GetID())), 0.2)
				end
			end
		end

		-- If we're stuck then call the HandleStuck function and abandon
		if ( self.loco:IsStuck() ) then

			self:HandleStuck()

			return "stuck"

		end

		--
		-- If they set maxage on options then make sure the path is younger than it
		--
		if ( options.maxage ) then
			if ( path:GetAge() > options.maxage ) then return "timeout" end
		end

		--
		-- If they set repath then rebuild the path every x seconds
		--
		if ( options.repath ) then
			if ( path:GetAge() > options.repath ) then path:Compute( self, pos ) end
		end

		coroutine.yield()

	end

	return "ok"

end

function ENT:GetPathGenerator()
	return function( area, fromArea, ladder, elevator, length )
		if ( !IsValid( fromArea ) ) then
			return 0
		else
			if ( !self.loco:IsAreaTraversable( area ) ) then
				return -1
			end

			local dist = 0

			if ( IsValid( ladder ) ) then
				dist = ladder:GetLength()
			elseif ( length > 0 ) then
				dist = length
			else
				dist = (area:GetCenter() - fromArea:GetCenter()):GetLength()
			end

			local cost = dist + fromArea:GetCostSoFar()

			local deltaZ = fromArea:ComputeAdjacentConnectionHeightChange( area )
			if ( deltaZ >= self.loco:GetStepHeight() ) then
				if ( deltaZ >= self.loco:GetMaxJumpHeight() ) then
					return -1
				end

				local jumpPenalty = 5
				cost = cost + jumpPenalty * dist
			elseif ( deltaZ < -self.loco:GetDeathDropHeight() ) then
				return -1
			end

			return cost
		end
	end
end