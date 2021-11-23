local nx = NX
local dt = NX.Detection:new("bhop", 1)
dt.Viols = {} -- amt of perfect hops
dt.SusJumps = {} -- amt of hops with space held (ie, not tapping it before landing)

dt.Times = {} -- hop times
dt.Was = {}   -- player's last tick's IN_JUMP state
dt.SpaceHeld = {}

local jumpLen = 0.3
local needViolations = 10

hook.Add("StartCommand", "NX_BHop", function(ply, cmd)
	if NX.ShouldIgnore(ply) then return end

	dt.Viols[ply] = dt.Viols[ply] or 0
	dt.Times[ply] = dt.Times[ply] or 0
	dt.SusJumps[ply] = dt.SusJumps[ply] or 0

	local jump = cmd:KeyDown(IN_JUMP)
	local ground = ply:IsOnGround()

	if not jump and ground then
		-- on ground with no bhop; reset violation

		if dt.Viols[ply] + dt.SusJumps[ply] >= needViolations then
			dt:Detect(ply, {
				PerfectHops = dt.Viols[ply],
				HeldSpaceHops = dt.SusJumps[ply]
			})
		end

		dt.Times[ply] = 0
		dt.Viols[ply] = 0
		dt.SusJumps[ply] = 0
	end

	if jump and not dt.Was[ply] then
		-- jump held and it wasn't held
		if not ground then
			dt.Times[ply] = 0
			goto finish
		end

		-- jump held, wasn't held, and is on ground
		local ct = CurTime()

		-- not much time has passed since last hop; just push time forwards
		if ct - dt.Times[ply] < jumpLen then
			dt.Times[ply] = ct
			goto finish
		end

		local held = dt.SpaceHeld[ply] and dt.SpaceHeld[ply] > 0 and (ct - dt.SpaceHeld[ply] > jumpLen)

		dt.Viols[ply] = dt.Viols[ply] + 1
		dt.SusJumps[ply] = dt.SusJumps[ply] + (held and 1 or 0)
		dt.Times[ply] = ct

		-- count up the violations until they stop
	end

	::finish::
	dt.Was[ply] = jump
end)

hook.Add("PlayerButtonDown", "NX_BHopTest", function(ply, btn)
	if btn ~= KEY_SPACE then return end
	dt.SpaceHeld[ply] = CurTime()
end)

hook.Add("PlayerButtonUp", "NX_BHopTest", function(ply, btn)
	if btn ~= KEY_SPACE then return end
	dt.SpaceHeld[ply] = -CurTime()
end)