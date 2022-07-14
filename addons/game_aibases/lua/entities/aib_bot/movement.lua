--[[
	reference point: https://github.com/lua9520/source-engine-2018-hl2_src/blob/3bf9df6b2785fa6d951086978a3e66f49427166a/game/server/hl2/npc_combine.cpp
	https://insurgencysandstorm.mod.io/improvedai

	TODO:
		- when running low on mag, start moving & shooting towards nearest cover
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

	self._continueMove = nil
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

	if self.debug then
		print("next move found at", CurTime())
	end

	self:StartActivity(ACT_RUN)

	self.loco:SetDesiredSpeed(self.MoveSpeed)

	self.WantMoveWhere = nil
	self:MoveToPos(p)
	self:StartActivity(self:GetDesiredActivity())

	local pr = self._movePr

	if pr then
		self._movePr = nil
		pr:Resolve()
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

		print("chasing")
	
		if aws then
			self:AimAt(aws.pos + (aws.vel or vector_origin) * 0.3)
			print("reading ahead")
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

function ENT:PickNextPatrol()
	local en = self:GetEnemy()
	local mood = self:GetMood()

	if en or mood ~= "passive" then return end

	local patr = self.PatrolRoute

	-- TODO: closures
	self.MoveSpeed = self.PatrolSpeed

	local cur = incr(self.CurrentPatrolPoint, #patr)
	local curPt = self.PatrolRoute[cur]

	self._patrolPr = self:MoveWhenCan(curPt)
		:Then(function()
			local nxt = incr(cur, #patr)
			local nxtPt = self.PatrolRoute[nxt]

			local min, max = 0, 0 -- min/max delays

			if self:GetPos():Distance(nxtPt) < 32 then
				cur = incr(cur, #patr) -- skip the next point but aim in its' direction
				self.CurrentPatrolPoint = cur

				local aimAt = curPt + (nxtPt - curPt):GetNormalized():CMul(128)
				aimAt.z = self:GetShootPos().z

				debugoverlay.Cross(aimAt, 8, 2, Colors.Yellowish, true)

				self:RestartCoro("Movement")
				self:SetAimingAt( aimAt )
				self._patrolAim = aimAt

				min = 0.9
				max = 1.3
			end

			self:Timer("wait_patrol", math.Rand(min, max), 1, function()
				self:PickNextPatrol()
			end)
		end)

	self.CurrentPatrolPoint = cur
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

	if en and not can then
		local chase, why = self:ShouldChase(time, lastPos)

		if chase then
			self:TryChase(lastPos)
		else
			--print(why)
		end
	end

	local mood = self:GetMood()

	if not en and mood == "passive" then
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

function ENT:MoveToPos( pos, options )
	options = options or {}

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 20 )
	path:Compute( self, pos, self:GetPathGenerator() )

	if ( !path:IsValid() ) then return "failed" end

	self._continueMove = true

	local curAim = Vector()
	local already_aimed = nil --self._patrolAim -- this is kind of a huge hack lmao
	self._patrolAim = nil

	if self.debug then
		print("New move started @", CurTime())
	end

	while ( path:IsValid() and self._continueMove ) do

		path:Update( self )

		local cur = not already_aimed and self:GetMood() == "passive" and path:GetCurrentGoal()

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
		end

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
			if ( path:GetAge() > options.repath ) then path:Compute( self, pos ) end
		end

		coroutine.yield()
	end

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