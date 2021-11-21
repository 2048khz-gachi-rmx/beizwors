local CrouchData = {}
setfenv(1, _G)
local function removeCrouch(mv)
	mv:SetButtons( bit.band(bit.bnot(IN_DUCK), mv:GetButtons()) )
end

local dodraw = {}
local function addtr(start, endpos, min, max)
	local t = {
		Vector(), Vector(), min, max
	}

	table.insert(dodraw, t)

	t[1]:Set(start)
	t[2]:Set(endpos)
end

local ROT_ANG = Angle(0, 90)

hook.Add("Move", "NoCrouchSpam", function(ply, mv)
	do return end
	local dat = CrouchData[ply] or {}
	CrouchData[ply] = dat

	local wasGround = dat.OnGround
	dat.OnGround = ply:OnGround()
	local og = dat.OnGround

	local ducking = bit.band(mv:GetButtons(), IN_DUCK) > 0

	local wasDuck = dat.Ducking
	dat.Ducking = ducking

	if not og and wasGround then
		dat.StartedOnGround = wasDuck
	end

	if not (ducking and not og and not dat.StartedOnGround) then
		dat.RegHull = nil
		dat.DuckHull = nil
		return
	end

	--print(ducking, og, dat.StartedOnGround)

	-- holding duck and didnt start jump while ducked; shift might happen

	--print("ducking without starting; thonking")
	dat.WantDuck = true

	local vel = mv:GetVelocity()
	vel:Mul(engine.TickInterval() * 3)

	-- they'll move this about much; look ahead by a few ticks just in case

	-- can they fit wherever they're going with current hull?
	local min, max = ply:GetHull()

	local ep = mv:GetOrigin()
	ep:Add(vel)

	local trTbl = {
		start = mv:GetOrigin(),
		endpos = ep,
		mins = min, maxs = max,
		filter = ply,
		collisiongroup = ply:GetCollisionGroup(), -- stop spawnpoints being gay
		mask = MASK_PLAYERSOLID,
	}

	local tr = util.TraceHull(trTbl)

	trTbl.output = tr
	dat.RegHull = {
		Vector(trTbl.start), Vector(trTbl.endpos),
		min, max
	}

	dat.HitReg = tr.Hit

	if tr.Hit then
		-- they can't fit with current hull, can they fit with duck hull?
		min, max = ply:GetHullDuck()

		if not dat.StartedOnGround then
			-- because they didnt start off ground,
			-- duck hull will be aligned by top to original hull
			-- cuz thats how crouch jump works ig?
			trTbl.start:Add(Vector(0, 0, trTbl.maxs.z - max.z))
		end

		trTbl.mins, trTbl.maxs = min, max

		util.TraceHull(trTbl)

		if tr.Hit then
			-- check what we hit; we mightve just hit the floor or something
			tr.HitNormal:Rotate(ROT_ANG)
			tr.HitNormal:Mul(vel:GetNormalized():Dot(tr.HitNormal))
			local newvel = tr.HitNormal

			trTbl.endpos:Set(trTbl.start)
			trTbl.endpos:Add(newvel)

			-- if we hit the floor, dot should be high and this should essentially
			-- slide along the surface
			-- otherwise, it'll just hit the wall in front of us
			util.TraceHull(trTbl)

			print("first hit", tr.Hit)
			--addtr(trTbl.start, trTbl.endpos, min, max)

			if not tr.Hit then
				-- well we wouldnt hit it if we crouched

				trTbl.start = mv:GetOrigin()
				trTbl.endpos:Set(trTbl.start)
				trTbl.endpos:Add(newvel)

				addtr(trTbl.start, trTbl.endpos, min, max)
				util.TraceHull(trTbl)
				print(Realm(), "aeiou", tr.Hit)
				--if tr.Hit then
					return
				--end
			end

			-- u dont fit either way fatass
			--[[removeCrouch(mv)
			print("PASS")
			return]]
		end
	end

	--print("lol eat shit")
	removeCrouch(mv)
end)

hook.Add("PostDrawTranslucentRenderables", "gay", function()
	local lp = LocalPlayer()
	local dat = CrouchData[lp]
	if not dat then return end

	--[[for k,v in ipairs(dodraw) do
		render.DrawWireframeBox(v[1], Angle(), v[3], v[4], Colors.Sky, false)
		render.DrawWireframeBox(v[2], Angle(), v[3], v[4], color_white, false)
	end

	if FrameNumber() % 300 == 0 then
		for i=1, #dodraw do
			dodraw[i] = nil
		end
	end]]
end)