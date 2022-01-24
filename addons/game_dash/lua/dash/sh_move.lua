--
Dash.Table = Dash.Table or {} -- table of dashing people
local DashTable = Dash.Table

Dash.DashTime = 0.3
Dash.DashCooldown = 1

local function getNw(ply)
	if CLIENT then ply = CachedLocalPlayer() end

	local key = "dash" .. ply:UserID()
	local ret = _NetworkableCache[key]

	if not ret then
		ret = PredNetworkable(key)
		ret:Bind(ply)
	end

	ret:Alias("Dashing", 2, "Bool")

	return ret
end

function Dash.OnGround(ply)
	if Offhand.GetCooldown("Dash", ply) == math.huge then
		Offhand.SetCooldown("Dash", ply, CurTime() + Dash.DashCooldown)
		return true
	elseif not ply:GetNW2Bool("DashReady") and Offhand.GetCooldown("Dash", ply) == 0 then
		ply:SetNW2Bool("DashReady", true)
		if Dash.OnReady then Dash.OnReady(ply) end
	end
end

hook.Add("OnPlayerHitGround", "Dash_StartRecharge", function(ply, water, floater, speed)
	local afterDash = Dash.OnGround(ply)
	if afterDash then
		ply._stopFall = afterDash
	end
end)

hook.Add("GetFallDamage", "Dash_NoFall", function(ply)
	if ply._stopFall then ply._stopFall = nil return 0 end
end)

local function IsDashing(ply)
	return getNw(ply):Get("Dashing", false)
end

local function SetDashing(ply, b)
	getNw(ply):Set("Dashing", b)
end

function Dash.CheckMoves(ply, mv, dir)
	local dt = DashTable[ply]
	if not dt then return end --ok?

	local jumping = mv:KeyDown(IN_JUMP) -- or dt.Jumped
	local ducked = 	mv:KeyDown(IN_DUCK)  -- or dt.Ducked

	if not IsDashing(ply) then return end
	if not jumping then return end

	local pos = mv:GetOrigin()

	if dt.ground then
		if dt.jump or dt.down then return end

		local tr = util.TraceHull({
			start = pos + Vector(0, 0, 8),
			endpos = pos - Vector(0, 0, 16),
			filter = ply,
			mins = Vector( -16, -16, -4 ),
			maxs = Vector( 16, 16, 4 ),
			mask = bit.bor(MASK_SOLID, MASK_WATER)
		})

		if tr.Hit then
			local vel

			--self:SetDashCooldown(1.5)

			if IsFirstTimePredicted() then
				--self.CooldownDuration = self:GetDashCooldown()
			end

			if ducked then
				vel = dir * 2350
				vel.z = 300
				-- self:SetDashCooldown(3)
			else
				vel = dir * 1500
				vel.z = 400
			end

			Dash.Stop(ply)
			ply:SetNW2Bool("Dash_SuperMoving", true)
			ply:SetNW2Bool("Dash_PostSuperMove", true)

			dt.SuperMovingVelocity = vel

			if SERVER then
				ply:GetCurrentCommand():RemoveKey(IN_JUMP)
			end

			return
		end

	else --Dash started in mid-air
		-- Player must dash without space and downwards
		if dt.jump or not dt.down then return end

		local tr = util.TraceHull({
			start = pos + Vector(0, 0, 12),
			endpos = pos - Vector(0, 0, 24),
			filter = ply,
			mins = Vector( -24, -24, -4 ),
			maxs = Vector( 24, 24, 8 ),
			mask = bit.bor(MASK_SOLID, MASK_WATER)
		})

		if tr.Hit then
			local vel

			local dir = Vector()
			dir:Set(dt.dir)
			dir.z = math.min(-dir.z, 0.9) -- dt.down implies dir.z is < -0.15
										  -- the lower dir.z was, the bigger the bounce

			local mul = 2000 * (1 - dir.z) -- and the bigger the bounce, the less velocity you have

			vel = dir * mul
			vel.z = math.max(vel.z * (dir.z > 0.6 and (0.77 / (1 - dir.z)) or 1), 400)

			Dash.Stop(ply)
			ply:SetNW2Bool("Dash_SuperMoving", true)
			ply:SetNW2Bool("Dash_PostSuperMove", true)

			ply._stopFall = true
			dt.SuperMovingVelocity = vel

			if SERVER then
				ply:GetCurrentCommand():RemoveKey(IN_JUMP)
			end
		end
	end

end

hook.Add("FinishMove", "Dash_DoMove", function(ply, mv, cmd)
	if CLIENT and ply ~= CachedLocalPlayer() then
		return
	end

	if not (SERVER and DashTable[ply] or IsDashing(ply)) and ply:OnGround() then
		Dash.OnGround(ply)
	end

	if not DashTable[ply] then return end
	local t = DashTable[ply]

	if t.EndSuperMove and SERVER then
		if mv:GetVelocity():Length() < 600 or ply:IsOnGround() or ply:WaterLevel() >= 1 then
			ply:SetNW2Bool("Dash_SuperMoving", false)
			ply:SetNW2Bool("Dash_PostSuperMove", false)
			ply:SetNW2Bool("Dash_Post", false)

			ply.EndSuperMove = nil
			ply.Dashed = false
		end
	end

	local time = t.t

	local curt = CurTime()
	if curt <= time then return end -- before dash

	local d = t.dir

	local newvel = t.newvel or d * 800

	Dash.CheckMoves(ply, mv, d)
	-- self:CheckMoves(ply, mv, d)
	local smv = ply:GetNW2Bool("Dash_SuperMoving", false)
	-- local psmv = ply:GetNW2Bool("Dash_PostSuperMove", false)
	-- local pds = ply:GetNW2Bool("Dash_Post", false)
	local dashing = IsDashing(ply) -- ply:GetNW2Bool("Dashing", false)
	--clprint("dashing:", dashing)
	if smv then
		mv:SetMaxSpeed(10e9)
		mv:SetVelocity(t.SuperMovingVelocity)

		ply:SetNW2Bool("Dash_SuperMoving", false)
		return
	end

	if not dashing then return end
	local endtime = time + Dash.DashTime

	if curt > endtime then
		Dash.Stop(ply)
	else
		-- time not up; continue dashing
		mv:SetVelocity(newvel)
		ply:SetNW2Float("CT", CurTime())
	end
end)

function Dash.Begin(ply)
	if not ply:GetNW2Bool("DashReady", true) then
		print("dash not ready", Realm())
		return false
	end

	local dir = ply:EyeAngles():Forward()
	local z = dir.z
	if z > -0.15 and z < 0.20 then
		dir.z = 0.1
	end

	--ply:SetNW2Bool("Dashing", true)
	SetDashing(ply, true)

	ply:SetNW2Bool("PostDash", true)
	ply:SetNW2Bool("DashReady", false)

	if SERVER or IsFirstTimePredicted() then
		DashTable[ply] = {
			t = CurTime(),
			dir = dir,
			ground = ply:IsOnGround() or ply:WaterLevel() >= 1,
			jump = ply:KeyDown(IN_JUMP),
			down = dir.z < -0.15
		}
	end
end


function Dash.Stop(ply)
	-- nil the table serverside; cl we need the pred so use nw2
	if SERVER then DashTable[ply] = nil end
	--ply:SetNW2Bool("Dashing", false)
	SetDashing(ply, false)
end