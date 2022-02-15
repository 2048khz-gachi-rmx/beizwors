local nx = NX
local dt = NX.Detection:new("norecoil", 2)
dt.ADelta = {}

-- because mouseY and viewangles can mismatch for some time, we do this too
local timeToDetect = 0.9
local timeToBypassDetect = 0.5

local trkBullets = 3

hook.Add("StartCommand", "NX_Norecoil", function(ply, cmd)
	if NX.ShouldIgnore(ply) then return end

	local wep = ply:GetActiveWeapon()
	if not wep or not wep:IsValid() or not wep.ArcCW then return end

	local dat = dt.ADelta[ply] or {}
	dt.ADelta[ply] = dat

	if wep:GetRecoil() == 0 then
		if not dat.st then return end
		--dat.r = 0
		dat.my = 0
		dat.p = nil -- punch
		dat.d = nil -- total delta
		dat.l = nil -- last pitch
		dat.ended = dat.st or 0
		dat.st = nil -- start of recoil
		dat.stAng = nil -- start's pitch

		dat.bulAngs = nil
		return
	end

	dt:RemoveTimer(ply)
	local ang = cmd:GetViewAngles()
	local passed = CurTime() - wep:GetRecoiledWhen()

	local delta = -(ang.p - (dat.l or ang.p)) -- + = up

	local pre = dat.l

	if not dat.l then
		dat.stAng = ang.p
	end

	dat.l = ang.p
	dat.st = dat.st or CurTime()
	dat.bulAngs = dat.bulAngs or {}

	--dat.r = (dat.r or 0) + wep:GetRecoil()

	-- if they flail their mouse around, it might eat shit due to ping

	local my = cmd:GetMouseY() / 2

	if ang.p > 88 then
		-- ignore MY going down when their angle has nowhere to go
		my = math.min(0, my)
	end

	dat.my = math.max(-5, (dat.my or 0) + my)

	dat.d = (dat.d or 0) + delta
	dat.p = dat.p or 0
	dat.usep = math.min(dat.p, math.Approach(dat.usep or 0, dat.p, engine.TickInterval() * 5))

	if dat.usep < 2 then return end -- dont even bother for small recoil

	local sinceStart = CurTime() - dat.st
	local sinceLast = dat.st - (dat.ended or 0)

	if sinceLast > wep.RecoilTRecovery and dat.ended then
		dat.viols = 0
		dat.ended = nil
	end

	-- ignore start of spray
	local is_start = sinceStart < 0.25
	if is_start then return end

	local offAmt = dat.d - dat.p

	if offAmt > dat.p * 15 and dat.p > 0 then
		dat.d = 0 -- too far off-center: take this new position as our new anchor
		dat.p = 0
	end

	if offAmt > dat.p * 0.5 then return end -- the aim is off-center

	local punchMult = 1.5 -- punch -> angle (this is a random number picked by trial and error)

	-- they dont move their mouse enough
	local mouse_bad = ang.p < 88 and dat.my < dat.usep * punchMult

	--[[if true then
		printf("bad mouse? %s: %d < %d", mouse_bad, dat.my, dat.usep * punchMult)
		printf("	aim offset: %.3f, %.3f\n", offAmt, dat.usep * 0.5)
	end]]

	-- or they try too hard to pretend
	local pull_too_much = dat.my > dat.p * 200 and -- mouseY is through the fucking roof
		offAmt > dat.p * -punchMult -- but their aim is not too low


	if pull_too_much and ang.p < 85 then -- if they look straight down they can pull too much
		for i=1, trkBullets do
			if not dat.bulAngs[i] then break end
			local bulOff = dat.stAng - dat.bulAngs[i] -- how far off-center the bullet went out

			if bulOff < -6 or bulOff > 6 then
				-- the bullets are going everywhere on the Y axis; they're probably just flailing
				pull_too_much = false
				break
			end
		end

		if pull_too_much then
			dat.stByp = dat.stByp or CurTime()

			-- this has been going on for a while now
			if CurTime() - dat.stByp > timeToBypassDetect then
				mouse_bad = mouse_bad or pull_too_much
			end
		end
	elseif dat.stByp then
		dat.bypCd = (dat.bypCd or 0) + engine.TickInterval()
		if dat.bypCd > timeToBypassDetect then
			dat.bypCd = nil
			dat.stByp = nil
		end
	end

	if not mouse_bad then return end

	if ang.p >= -85 -- they dont look straight up (cuz recoil would have nowhere to go)
		then

		--if cmd:GetMouseY() + 2 < wep:GetRecoil() * 4 then
			dat.viols = (dat.viols or 0) + 1
			--print(dat.viols, 1 / engine.TickInterval() * timeToDetect)
			print("detected norecoil!", ply, dat.my, dat.usep * 10)
			if dat.viols > 1 / engine.TickInterval() * timeToDetect then
				dt:Detect(ply, {
					MYSum = dat.my,
					OffCenter = dat.d,
					PunchSum = dat.p,
					AttemptedBypass = pull_too_much or nil,
					--RecoilSum = dat.r,
				})
			end
		--end

	end
end)

hook.Add("ArcCW_FiredBullets", "NX_Norecoil", function(wep)
	local ow = wep:GetOwner()
	local dat = dt.ADelta[ow]

	if not dat then return end

	dat.bulAngs = dat.bulAngs or {}
	table.insert(dat.bulAngs, 1, ow:EyeAngles().p)
	dat.bulAngs[trkBullets + 1] = nil
end)

hook.Add("ArcCW_Punch", "NX_Norecoil", function(wep, punch)
	local ply = wep:GetOwner()
	local dat = dt.ADelta[ply] or {}
	dt.ADelta[ply] = dat

	dat.p = (dat.p or 0) + punch * 0.7
end)