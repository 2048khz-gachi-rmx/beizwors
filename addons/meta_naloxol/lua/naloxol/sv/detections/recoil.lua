local nx = NX
local dt = NX.Detection:new("norecoil", 2)
dt.ADelta = {}

local timeToDetect = 0.7

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
		return
	end

	dt:RemoveTimer(ply)
	local ang = cmd:GetViewAngles()
	local passed = CurTime() - wep:GetRecoiledWhen()

	local delta = -(ang.p - (dat.l or ang.p)) -- + = up
	local pre = dat.l

	dat.l = ang.p
	dat.st = dat.st or CurTime()
	--dat.r = (dat.r or 0) + wep:GetRecoil()
	dat.my = (dat.my or 0) + cmd:GetMouseY() / 2
	dat.d = (dat.d or 0) + delta
	dat.p = dat.p or 0

	local sinceStart = CurTime() - dat.st
	local sinceLast = dat.st - (dat.ended or 0)

	if sinceLast > 0.3 and dat.ended then
		dat.viols = 0
		dat.ended = nil
	end

	if sinceStart > 0.1 and -- let the ucmds catch up (dumbass engine)
		dat.my < dat.p * 20 and -- they dont move their mouse enough
		dat.d < dat.p and -- right now, their recoil is controlled (not far off the center)
		ang.p >= -85 and -- they dont look straight up (cuz recoil would have nowhere to go)
		passed < wep.RecoilTRecovery * 0.4 then
		if cmd:GetMouseY() + 2 < wep:GetRecoil() * 4 then
			dat.viols = (dat.viols or 0) + 1
			if dat.viols > 1 / engine.TickInterval() * timeToDetect then
				dt:Detect(ply, {
					MYSum = dat.my,
					OffCenter = dat.d,
					PunchSum = dat.p,
					--RecoilSum = dat.r,
				})
			end
		end
	end
end)

hook.Add("ArcCW_Punch", "NX_Norecoil", function(wep, punch)
	local ply = wep:GetOwner()
	local dat = dt.ADelta[ply] or {}
	dt.ADelta[ply] = dat

	dat.p = (dat.p or 0) + punch
end)