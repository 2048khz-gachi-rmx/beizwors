--

local nx = NX
local dt = NX.Detection:new("fakeangles", 0)
dt.Viols = {}
dt.Ignore = {}
dt.ProcessQueue = muldim:new()

local tint = engine.TickInterval()
local violToDet = 0.2

local tAng = Angle()

local function doProcess(ply)
	local diff = 0
	local t = dt.ProcessQueue:Get(ply)
	if #t <= 1 then return end -- dont use this detection at all

	local last = t[#t]
	local curPreLast = t[1]

	local avgPreLast = 0


	for i=1, #t - 1 do
		local ta = t[i]
		tAng:Set(ta)
		tAng:Sub(last)
		tAng:Normalize()

		diff = math.max(diff,
			math.abs(tAng[1]) + math.abs(tAng[2]) + math.abs(tAng[3]))

		tAng:Set(ta)
		tAng:Sub(curPreLast)
		tAng:Normalize()

		local addAvg = math.abs(tAng[1]) % 90 + math.abs(tAng[2]) % 180 + math.abs(tAng[3])
		curPreLast = ta
		avgPreLast = avgPreLast + addAvg
	end

	if diff > 45 and (t.MX + t.MY) < 250 then
		return true, diff, t.MX, t.MY
	end

	return false
end

hook.Add("SetupMove", "NX_Fakeangles", function(ply, mv, cmd)
	if NX.ShouldIgnore(ply) then return end

	local prev = dt.ProcessQueue:Get(ply, "Tick")
	local ct = engine.TickCount()

	local ang = cmd:GetViewAngles()

	if math.abs(ang[1]) > 90 then
		dt:Detect(ply, "invalid_pitch:" .. ang[1])
	elseif math.abs(ang[2]) > 181 then
		dt:Detect(ply, "invalid_yaw:" .. ang[2])
	end

	if not prev then
		dt.ProcessQueue:Set(ct, ply, "Tick")
	elseif prev ~= ct then
		local viol, diff, mx, my = doProcess(ply)

		dt.ProcessQueue:Set(nil, ply)
		dt.ProcessQueue:Set(ct, ply, "Tick")
		dt.ProcessQueue:Set(0, ply, "MX")
		dt.ProcessQueue:Set(0, ply, "MY")

		if viol then
			local max = violToDet + ply:Ping() / 500
			dt.Viols[ply] = math.min( (dt.Viols[ply] or 0) + tint, max )

			if dt.Viols[ply] == max then
				dt:Detect(ply, {
					MouseX = mx,
					MouseY = my,
					AngDiff = diff,
				})
			end
		elseif viol ~= nil then
			dt.Viols[ply] = math.max( (dt.Viols[ply] or 0) - tint, 0 )
		end
	end

	dt.ProcessQueue:Insert(ang, ply)
	dt.ProcessQueue:Set( (dt.ProcessQueue:Get(ply, "MX") or 0) + math.abs(cmd:GetMouseX()), ply, "MX" )
	dt.ProcessQueue:Set( (dt.ProcessQueue:Get(ply, "MY") or 0) + math.abs(cmd:GetMouseY()), ply, "MY" )
end)

local PLAYER = FindMetaTable("Player")

PLAYER._SetEyeAnglesOld = PLAYER._SetEyeAnglesOld or PLAYER.SetEyeAngles
function PLAYER:SetEyeAngles( ang )
	dt.Ignore[self] = CurTime()

	return PLAYER._SetEyeAnglesOld(self, ang)
end