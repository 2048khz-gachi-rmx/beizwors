--[[
	reference point: https://github.com/lua9520/source-engine-2018-hl2_src/blob/3bf9df6b2785fa6d951086978a3e66f49427166a/game/server/hl2/npc_combine.cpp
	https://insurgencysandstorm.mod.io/improvedai

	TODO:
		- when running low on mag, start WantMoveWhere & shooting towards nearest cover
			when completely out, run towards it instead while reloading

]]
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
		return false
	else
		self:MoveWhenCan(pos)
		return true
	end
end

function ENT:AbortMove()
	if self._movePr then
		self._movePr:Reject()
		self._movePr = nil
	end

	if self._continueMove then
		self._continueMove:Invalidate()
	end
end

function ENT:C_MoveNow(pos)
	-- yield and return whether we moved successfully or were interrupted
	self.WantMoveWhere = pos
	local coro = coroutine.running()

	self:AbortMove()

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

	self:AbortMove()
	self._movePr = Promise()
	return self._movePr
end

function ENT:GetMovePromise()
	return self._movePr
end

function ENT:DoQueuedMove()
	-- called from behavior coro
	local p = self.WantMoveWhere
	if not p then return end

	if self.debug then
		print("next move found at", CurTime())
	end

	self:StartActivity(ACT_RUN)

	self.loco:SetDesiredSpeed(self.MoveSpeed)

	self.WantMoveWhere = nil
	local pr = self._movePr

	self:MoveToPos(p)
	self:StartActivity(self:GetDesiredActivity())

	if not pr:IsFinished() then
		self._movePr = nil
		pr:Resolve()
	end
	--self:DoQueuedMove(pos)
end

function ENT:WantReload(tac, top)
	local wep = self:GetCurrentWeapon()

	if wep:Clip1() < wep:GetMaxClip1() * ((top and 1) or (tac and 0.75) or 0.3) then
		return true
	end

	return false
end

function ENT:TakeCover()
	local spot = self:FindSpot("near")
	if not spot then return Promise():Reject() end

	local pr = self:MoveWhenCan(spot)
	return pr
end

ENT.ChaseChainDelay = 0.7
ENT.InitialChaseDelay = 4
ENT._curChaseDelay = ENT.InitialChaseDelay

function ENT:TryChase(sightOf)
	--[[local t = {
		pos = self:GetPos(),
		radius = 192,
	}

	local have_cover = self:FindSpot("random", t)

	t.pos = sightOf
	local will_have = self:FindSpot("random", t)

	if will_have or not have_cover then]]

		self._curChaseDelay = self.ChaseChainDelay

		local chasing = true

		self:Once("EnemyFound", function()
			self.ChasedAndLost = nil

			-- found target while chasing; abort chase and fire
			if chasing then
				self:AbortMove()
				chasing = false
			end
		end)

		local aws = self:GetTargetAwareness()

		if aws then
			self:AimAt(aws.pos + (aws.vel or vector_origin) * 0.3)
			debugoverlay.Sphere(aws.pos, 3, 2, Colors.Sky, true)
			debugoverlay.Line(aws.pos, aws.pos + (aws.vel or vector_origin) * 0.3, 2, Colors.Green, true)
		else
			print("somehow chasing with no target awareness")
		end

		self.MoveSpeed = self.EngageSpeed
		self:C_MoveNow(sightOf)

		chasing = false
		self:HaveEnemy()
		self:UpdateTargetLOS()

		if self:GetEnemy() and not self:CanSeeTarget() then
			self.ChasedAndLost = true
			self._curChaseDelay = self.InitialChaseDelay
			print("lost after chase")
			--[[self:LoseEnemy()

			local cnav = navmesh.GetNavArea(self:GetPos(), 4)
			if not IsValid(cnav) then return end
			self:SetAimingAt(cnav:GetCenter())]]
		end
	--end
end

function ENT:ShouldChase(time, sightOf)
	if time < self._curChaseDelay then return false, "time" end
	if self.ChasedAndLost then return false, "lost" end
	if self:HasActivity("Reload") then return false, "reloading" end
	if self:GetPos():Distance(sightOf) < 8 then return false, "far" end
	if not self:GetEnemy() then return false, "wtf" end

	-- todo: camping?

	return true
end

local function incr(cur, total)
	return (cur % total) + 1
end

local function decr(cur, total)
	return (cur - 2) % total + 1
end

function ENT:ShouldPatrol()
	if self:GetEnemy() then return false end
	if self:GetMood() ~= "passive" then return false end

	if self:HasActivity("Reload") or self:HasActivity("Covering") then
		return false
	end

	return true
end

function ENT:AbortPatrol()
	if self._patrolPr and not self._patrolPr:IsFinished() then
		self._patrolPr:Reject()
	end
end

function ENT:PickNextPatrol()
	if not self:ShouldPatrol() then return end

	local patr = self.PatrolRoute

	-- TODO: closures
	self.MoveSpeed = self.PatrolSpeed

	local cur = self.CurrentPatrolPoint
	local curPt = self.PatrolRoute[cur]

	local new = incr(self.CurrentPatrolPoint, #patr)
	local newPt = self.PatrolRoute[new]

	local aimAt = newPt - (curPt - newPt):GetNormalized():CMul(128)
	aimAt.z = self:GetShootPos().z

	debugoverlay.Cross(aimAt, 8, 2, Colors.Yellowish, true)
	self:SetAimingAt( aimAt )
	self._patrolAim = aimAt

	self._patrolPr = self:MoveWhenCan(newPt)
		:Then(function()
			if not self:ShouldPatrol() then
				self.CurrentPatrolPoint = nil
				return
			end

			local min, max = 0, 0 -- min/max delays

			-- after we moved to this new point, shift 1 up
			cur = new
			curPt = newPt

			new = incr(cur, #patr)
			newPt = self.PatrolRoute[new]

			-- if after we moved to what is now our current point, the next point is hella close
			-- we turn, pull a driver ... for a bit then skip that point and go to the next one

			if self:GetPos():Distance(newPt) < 32 then
				new = incr(cur, #patr) -- skip the next point but aim in its' direction
				self.CurrentPatrolPoint = new

				-- re-aim while the timer's ticking
				aimAt = newPt - (curPt - newPt):GetNormalized():CMul(128)
				aimAt.z = self:GetShootPos().z

				debugoverlay.Cross(aimAt, 8, 2, Colors.Yellowish, true)
				self:SetAimingAt( aimAt )
				self._patrolAim = aimAt

				min = 0.9
				max = 1.3
			end

			self:RestartCoro("Movement")

			self:Timer("wait_patrol", math.Rand(min, max), 1, function()
				self:PickNextPatrol()
			end)
		end, function()
			self.CurrentPatrolPoint = nil -- aborted patrol?
		end)

	self._patrolPr.IsPatrol = true
	self.CurrentPatrolPoint = new
end

function ENT:DecideMovement()
	local en = self:GetEnemy()
	local postKill = self:HasActivity("PostKillReload")

	-- man im TERRIBLE at AI
	-- there's probably a proper way to branch behavior like this but ????????????

	if ((self.TargetAligned or self.TrackingEnemy) and en) or postKill then
		-- we have an enemy,

		local can, time = self:CanSeeTarget()
		if self:WantReload(true, postKill) and not can and time > 0.6 + math.random() then
			-- but we cant see them right now; piss off to cover and reload if needed
			self:RequestReload(postKill):Then(function()
				self.CurrentPatrolPoint = nil
			end)

			self:FinishActivity("PostKillReload")

			if postKill then
				self:SetMood("passive")
			end
			return
		end
	end

	local can, time, lastPos = self:CanSeeTarget()

	if en and not can then
		local chase, why = self:ShouldChase(time, lastPos)

		if chase then
			self:TryChase(lastPos)
		else
			--print(why)
		end
	end

	if self:ShouldPatrol() then
		local patr = self.PatrolRoute
		if not patr or #patr == 0 then return end

		local curPatr = self.CurrentPatrolPoint
		if not curPatr then
			-- find the closest patrol point to start from
			local cl, _, key = GetClosestVec(self:GetPos(), patr)
			if not cl then return end

			self.CurrentPatrolPoint = key

			self.MoveSpeed = self.PatrolSpeed

			self._patrolPr = self:MoveWhenCan(cl):Then(function()
				self:PickNextPatrol()
			end)
		end
	end
end

function ENT:IsMoving()
	return self._continueMove
end

function ENT:MoveToPos( pos, options )
	options = options or {repath = 1}

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 20 )
	path:Compute( self, pos, self:GetPathGenerator() )

	if ( !path:IsValid() ) then return "failed" end

	self._continueMove = path

	local curAim = Vector()
	local already_aimed = self._patrolAim -- this is kind of a huge hack lmao
	self._patrolAim = nil

	if self.debug then
		print("New move started @", CurTime(), self.loco:GetVelocity())
	end

	while ( path:IsValid() ) do

		path:Update( self )

		local cur = not already_aimed and self:GetMood() == "passive" and path:GetCurrentGoal()

		--[=[
		if cur and (not curAim or cur.pos ~= curAim) then
			curAim:Set(cur.pos)

			local dir = path:GetCursorData()

			local ep = cur.pos
			ep:Add(dir.forward:CMul(32))
			ep.z = self:GetShootPos().z

			debugoverlay.Sphere(ep, 4, 2, Colors.Reddish)
			self:SetAimingAt(ep)
			--[[local aimAt = Vector(cur.pos) + (cur.pos - self:EyePos()):GetNormalized() * 256
			aimAt.z = self:EyePos().z
			self:SetAimingAt(aimAt)
			debugoverlay.Sphere(aimAt, 4, 0.5, Colors.Sky, true)]]
		end]=]

		if self.debug then
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
			if ( path:GetAge() > options.repath ) then path:Compute( self, pos, self:GetPathGenerator() ) end
		end

		coroutine.yield()
	end

	self._continueMove = nil

	if self.debug then
		print("Move finished @", CurTime())
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