local nx = NX
local dt = NX.Detection:new("silentaim", 5)
dt.Viols = {}
dt.Passive = {}
dt.Active = {}
dt.LastAtk = {} -- i may be i may i may be slightly autistic
dt.WantTrack = {}
dt.DefaultCooldown = 0

local avgDeviatThres = 20
local closeThres = 5

local passiveSamples = 15 -- pre-attack
local discardLastPassive = 2

local activeSamples = 15 -- post-attack

local doAnalyze

hook.Add("SetupMove", "asd", function(ply, mv, cmd)
	if NX.ShouldIgnore(ply) then return end

	local atk = bit.band(cmd:GetButtons(), bit.bor(IN_ATTACK, IN_ATTACK2)) ~= 0

	local prev = dt.Passive[ply]
	local lastAtk = dt.LastAtk[ply]
	dt.LastAtk[ply] = atk

	if not prev then
		prev = Queue:new()
		dt.Passive[ply] = prev
	end

	local ang = cmd:GetViewAngles()

	local should_track = prev:Length() >= passiveSamples and -- have enough samples
		(prev.tracking or -- already tracking
			(atk and not lastAtk)) -- just pressed attack

	if not should_track then
		-- don't analyze, just store angle
		if prev:Length() >= passiveSamples then
			prev:Pop()
		end

		prev:Push(ang)

		return
	end

	local ac = dt.Active[ply]

	if not ac then
		ac = Queue:new()
		dt.Active[ply] = ac
	end

	-- previous frame wasnt attack but now its attack
	-- start tracking
	prev.tracking = true

	if ac:Length() > activeSamples then
		doAnalyze(ply, prev, ac)
		prev:Reset()
		prev.tracking = nil

		ac:Reset()
	else
		ac:Push(ang)
	end
end)

local trDat = {
	start = nil,
	endpos = nil,

	filter = nil,
}

local diff = Angle()
local avgdiff = Angle()
local actdiff = Angle()

function doAnalyze(ply, prev, act)
	local lang = prev:Pop()
	avgdiff:Zero()

	for i=1, passiveSamples - discardLastPassive do
		local cur = prev:Pop()
		diff:Set(lang)
		diff:Sub(cur)
		diff:Normalize()
		avgdiff:Add(diff)

		lang = cur
	end

	lang = prev:Last()

	avgdiff:Div(passiveSamples - discardLastPassive)

	local laang = lang

	local deviation = Angle()

	actdiff:Zero()

	local y_devs = {}
	local got_bad_dev = false

	for i=1, activeSamples - 1 do
		local cur = act:Pop()

		deviation:Set(laang)
		deviation:Sub(cur)
		deviation:Sub(avgdiff)
		deviation:Normalize()

		local p_dev = math.max(0, math.abs(deviation[1]) - 15)
		local y_dev = math.max(0, math.abs(deviation[2]) - avgDeviatThres) * math.Sign(deviation[2])

		if math.abs(y_dev) > 1 or got_bad_dev then
			got_bad_dev = math.max(got_bad_dev or 0, math.abs(y_dev))
			y_devs[#y_devs + 1] = y_dev
		end

		--print(i, y_dev, laang, cur, avgdiff)

		--[[diff:Set(laang)
		diff:Sub(cur)
		diff:Normalize()
		actdiff:Add(diff)]]

		laang = cur
	end

	actdiff:Div(activeSamples - 1)

	local sus = false

	--print(avgdiff[2], actdiff[2], #y_devs)

	for yd = 1, #y_devs - 1 do
		for yd2 = yd + 1, #y_devs do
			local dev = y_devs[yd] + y_devs[yd2]
			local diff = yd2 - yd
			--print("ae", actdiff[2], closeThres, math.abs(actdiff[2] * diff))
			if math.abs(dev) < closeThres + math.abs(actdiff[2] * diff) then
				--print("gotcha bitch", y_devs[yd], y_devs[yd2])
				sus = true
				break
			end
		end
	end

	if not sus then return end

	if dt.WantTrack[ply] and engine.TickCount() - dt.WantTrack[ply] < activeSamples + passiveSamples + 1 then
		dt:Detect(ply, {
			SnapAngle = got_bad_dev + avgDeviatThres
		})
	end
end


local trOut = {}
local trIn = {output = trOut}

hook.Add("ArcCW_FiredBullets", "NX_SAim", function(wep, bullet)
	local src = bullet.Src
	local dir = wep:GetOwner():GetAngles():Forward()

	trIn.start = src
	trIn.endpos = src + dir * 1024

	trIn.filter = wep:GetOwner()

	util.TraceLine(trIn)

	if IsPlayer(trOut.Entity) then
		dt.WantTrack[wep:GetOwner()] = engine.TickCount()
		print("fire")
	end
end)