local nx = NX
local dt = NX.Detection:new("fakelag", 3)

dt.cmNum = dt.cmNum or {}
dt.viols = dt.viols or {}
dt.violWhen = dt.violWhen or {}

local recv = 0
local lastTick = 0
local lastPly = nil
local det = false

hook.Add("SetupMove", "lol", function(ply, mv, cmd)
	if NX.ShouldIgnore(ply) then return end

	if lastPly ~= ply then
		recv = 0
		lastPly = ply
		det = false
	end

	if lastTick ~= engine.TickCount() then
		recv = 0
		lastTick = engine.TickCount()
		det = false
	end

	recv = recv + 1

	local ccn = cmd:CommandNumber()
	dt.cmNum[ply] = dt.cmNum[ply] or ccn - 1

	local ccnDiff = ccn - dt.cmNum[ply]
	dt.cmNum[ply] = ccn

	if (ccnDiff < 0 or ccnDiff > 4) and not det then
		det = true

		local vPassed = math.max(0, CurTime() - (dt.violWhen[ply] or CurTime()) - 1)
		dt.viols[ply] = math.max(0, (dt.viols[ply] or 0) + 1 - vPassed)
		dt.violWhen[ply] = CurTime()

		if dt.viols[ply] > 12 then
			dt:Detect(ply, {
				ArrivedCN = ccn,
				PreviousCN = ccn - ccnDiff,
				Times = dt.viols[ply],
			})
		end
	end

    --[[print(engine.TickCount(), cmd:CommandNumber(),
        ply:IsTimingOut(), ply:Ping(), CurTime(),
        cmd:GetButtons(), mv:GetOrigin())]]
end)