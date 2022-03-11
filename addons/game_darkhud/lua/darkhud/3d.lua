local dh = DarkHUD

local mx = Matrix()

local rt, mat = draw.GetRTMat("DarkHUD_Tilt", ScrW(), ScrH())
mat:Recompute()

dh:On("Rescale", "Tilt", function()
	rt, mat = draw.GetRTMat("DarkHUD_Tilt", ScrW(), ScrH())
end)
local smoke = Material("sprites/ar2_muzzle1")

local function pushStuff()
	if not DarkHUD.Setting3D:GetValue() then return end

	render.PushRenderTarget(rt)
	render.Clear(0, 0, 0, 0, true)
	render.OverrideAlphaWriteEnable(true, true)
end

local lastAng = Angle()
local diff_cur = Angle()
local diff_use = Angle()
local flat = Angle()

local diff_vec = Vector()
local diff_vecease = Vector()

local dir = 1
local side = 0



local function doRender(_, f)
	if not DarkHUD.Setting3D:GetValue() then return end

	render.PopRenderTarget()
	render.OverrideAlphaWriteEnable(false, true)

	local forward = ScrW() * (1.05 + side * .18)
	local right   = ScrW()
	local up      = ScrH()

	local yaw = -5 - 10 * dir
	local ea = EyeAngles()
	local ep = EyePos()

	local diff = ea - lastAng
	diff:Normalize()
	diff:Mul(0.5)
	diff.r = diff.p

	flat:Set(ea)
	flat.p = 0

	--diff.p = 0

	local max = ScrH() * 0.15

	local me = LocalPlayer()
	local realVel = me:InVehicle() and me:GetVehicle():GetVelocity() or me:GetVelocity()
	local vel = WorldToLocal(realVel, angle_zero,
		vector_origin, flat)

	local len = vel:Length()
	vel:Normalize()
	vel:Mul(math.min(len, 800) * 0.004)

	local vx = vel.x
	vel.x = vel.y
	vel.y = vel.z

	--diff_vec:Sub(prevVel)

	diff_vec:Add(vel)

	diff_vec[1] = diff_vec[1] + diff[2]
	diff_vec[2] = diff_vec[2] - diff[1]

	diff_vec = LerpVector(FrameTime() * 10, diff_vec, vector_origin)

	x, y = diff_vec:Unpack()

	local sx = math.Sign(x)
	local sy = math.Sign(y)

	local ease = 0.7
	diff_vecease[1] = math.min(math.abs(x) / max, 1) ^ ease * max * sx
	diff_vecease[2] = math.min(math.abs(y) / max, 1) ^ ease * max * sy
	diff_vecease[3] = vx * 25

	diff.r = diff.p / 2
	--diff.p = diff.y / 2

	diff.p = 0
	diff.y = 0

	diff_cur:Add(diff)
	diff_cur:Normalize()

	diff_cur = LerpAngle(FrameTime() * 7, diff_cur, angle_zero)
	diff_cur[1] = math.min(45, diff_cur[1] )

	diff_use:Set(diff_cur)
	diff_use.r = (math.abs(ea.p) / 90) ^ 3 * math.Sign(ea.p) * 15
	if diff_use.p < 0 then
		diff_use.p = diff_use.p / 2
	end
	diff_use.p = (diff_use.p + yaw) * dir

	diff_use:Normalize()

	local upRot = diff_use.r

	forward = forward --* (1 + upRot / 15 / 8)
	right = right * 1 --* (1 + upRot / 15 / div)
	up = up * 1 --* (1 - upRot / 15 / updiv)

	lastAng:Set(ea)

	local pos = ep
		+ ea:Forward() * forward
		- ea:Right() * right
		+ ea:Up() * up

	mx:Reset()

	mx:Translate(diff_vecease)
	mx:TranslateNumber(ScrW() * side, ScrH() / 2)
	mx:Rotate(diff_use)
	mx:TranslateNumber(-ScrW() * side, -ScrH() / 2)

	local ang_c = ea * 1 -- copies
	ang_c:RotateAroundAxis(ang_c:Forward(), 90)
	ang_c:RotateAroundAxis(ang_c:Right(), 90)
	ang_c:RotateAroundAxis(ang_c:Right(), yaw)

	cam.Start3D(nil, nil, 90)
	cam.Start3D2D(pos, ang_c, 2)

	--draw.EnableFilters()
	cam.PushModelMatrix(mx, true)

	surface.SetMaterial(mat)
	surface.SetDrawColor(255, 255, 255)
	surface.DrawTexturedRect(0, 0, ScrW(), ScrH())

	--surface.DrawOutlinedRect(0, 0, ScrW(), ScrH())

	cam.PopModelMatrix()
	cam.End3D2D()
	cam.End3D()
	

	--draw.DisableFilters()
end

dh:On("PrePaintVitals", "Tilt", pushStuff)
dh:On("PostPaintVitals", "Tilt", function(_, f)
	dir = 1
	side = 0
	doRender(_, f)
end)

dh:On("PrePaintAmmo", "Tilt", function()
	pushStuff()
	hook.Run("RenderRight3D")
end)

dh:On("PostPaintAmmo", "Tilt", function(_, f)
	--[[surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(MoarPanelsMats.gr)
	surface.DrawTexturedRect(ScrW() - 255, 0, 255, 255)
	surface.DrawOutlinedRect(0, 0, ScrW(), ScrH())]]

	dir = -1
	side = 1
	doRender(_, f)
end)