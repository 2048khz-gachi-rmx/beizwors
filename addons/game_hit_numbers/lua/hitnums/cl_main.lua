HDN = HDN or {}
HDN.Instances = HDN.Instances or muldim:new()
HDN.NPInstances = HDN.NPInstances or muldim:new()

HDN.Anim = Animatable("HDN")
local anim = HDN.Anim

HDN.Colors = {
	Damage = Color(230, 230, 230, 210),
	Outline = Color(0, 0, 0, 255),

	CritDamage = Color(230, 140, 140, 255),
	CritOutline = Color(120, 30, 30, 255),

	DeathDamage = Color(255, 50, 50, 255),
	DeathOutline = Color(80, 30, 30, 255),
}

HDN.ShakeLength = 0.4
HDN.MoveLength = 0.2
HDN.DisappearTime = 2
HDN.DisappearLen = 0.2

HDN.FontMain = "BSB64"

function HDN.AddIndicator(victim, dmg, crit, death, pos)
	local entry = {
		damage = dmg,
		crit = crit,
		pos = pos,
		when = CurTime(),
	}

	local insIn = IsPlayer(victim) and HDN.Instances or HDN.NPInstances
	local val, cur = insIn:Insert(entry, victim)

	local dat = insIn[victim]
	dat.total = (dat.total or 0) + dmg
	dat.totalAnim = dat.totalAnim or 0
	dat.lastDmg = CurTime()
	dat.firstDeal = dat.firstDeal or CurTime()
	dat.death = death
	dat.handle = dat.handle or util.GetPixelVisibleHandle()

	local sameTime = 0
	for k,v in ipairs(insIn[victim]) do
		if v.when == entry.when and entry ~= v then
			sameTime = sameTime + 1
		end
	end

	val.n = sameTime

	HDN.Anim:MemberLerp(dat, "totalAnim", dat.total, HDN.ShakeLength * (crit and 0.5 or 1), 0, 0.25)
end

net.Receive("bhdn_spawn", function()
	if not HDN.EnableSetting:GetValue() then return end

	local victim = net.ReadEntity()
	local dmg = net.ReadUInt(16)
	local crit = net.ReadBool()
	local death = net.ReadBool()
	local pos = net.ReadVector()

	HDN.AddIndicator(victim, dmg, crit, death, pos)
end)

local tVecs = {Vector(), Vector(), Vector()}
local tCols = {Color(0, 0, 0), Color(0, 0, 0)}

local ep, ev = EyePos(), EyeVector()

local mat

draw.PromiseMaterial("https://i.imgur.com/oQn4keo.png", "hmark128.png")
	:Then(function(_, newMat)
		mat = newMat
	end)

function HDN.DrawEntity(ent, dat)
	if #dat == 0 then return end
	if not ent:IsValid() then return end

	local pos = ent:GetPos()
	local tv = tVecs[1]

	render.SetMaterial(mat)
	local delay = 0.01

	for i=#dat, 1, -1 do
		local v = dat[i]
		local passed = CurTime() - v.when
		local fr

		if passed > v.n * delay then
			fr = math.RemapClamp(passed - v.n * delay, 0, 0.2, 1, 0)
		else
			local aT = v.n * delay
			fr = math.RemapClamp(passed - v.n * delay, -delay, 0, 0, 1)
		end

		fr = Ease(fr, 0.4)
		tv:Set(v.pos)
		tv:Add(pos)

		local sz = 8 * fr
		render.DrawSprite(tv, sz, sz, color_white)
	end
end

local function vecToScreen(v)
	local sdat = v:ToScreen()
	local vis = sdat.visible

	if vis and (sdat.x < -120 or sdat.x > ScrW() + 120) then -- Y axis is for losers
		vis = false
	end

	if not vis then return end

	return sdat.x, sdat.y
end

local mx = Matrix()
local col = Color(0, 0, 0)

local trIn, trOut = {}, {}

local function doTrace(to)
	trIn.filter = CachedLocalPlayer()
	trIn.start = ep
	trIn.endpos = to
	trIn.output = trOut

	return util.TraceLine(trIn)
end

function HDN.GetEntityVisPos(ent, dat, dopix)
	local hnPos

	local bone = ent:BoneToIndex("ValveBiped.Bip01_Head1")
	local handle = dat.handle

	if not bone then
		hnPos = dat[1] and dat[1].pos
			or ent:OBBCenter()

		if dopix then
			dat.vis = util.PixelVisible(hnPos, 12, handle)

			if CurTime() - dat.firstDeal < 0.2 then
				-- HOLY SHIT I HATE SOURCE
				local tr = doTrace(hnPos)
				local free = tr.Entity == ent or not tr.Hit
				dat.vis = free and 1 or 0
			end
		end
	else
		local matrix = ent:GetBoneMatrix(bone)
		if matrix then
			hnPos = matrix:GetTranslation()
		else
			hnPos = dat[1] and dat[1].pos
				or ent:OBBCenter()
		end

		if dopix then
			dat.vis = util.PixelVisible(hnPos, 12, handle) -- pixvis the bone pos, not above it

			if CurTime() - dat.firstDeal < 0.2 then
				-- HOLY SHIT I HATE SOURCE
				local tr = doTrace(hnPos)
				local free = tr.Entity == ent or not tr.Hit
				dat.vis = free and 1 or 0
			end
		end

		hnPos[3] = hnPos[3] + 8
	end

	return hnPos
end

function HDN.DrawEntityNumber(ent, dat, state, notfocus)
	if not IsValid(ent) then return true end

	local hnPos = HDN.GetEntityVisPos(ent, dat, true)
	local pixvis = (notfocus and 0) or dat.vis or 0 -- util.PixelVisible(hnPos, 12, dat.pixvis)

	--[[local attIdx = ent:LookupAttachment("eyes")

	if attIdx then
		local att = ent:GetAttachment(attIdx)
		hnPos = att and att.Pos

		if hnPos then
			hnPos[3] = hnPos[3] + 10
		end
	end]]

	local is_crit = false
	local is_last_crit = dat[#dat].crit
	local is_death = dat.death

	if not dat.death then
		for k,v in ipairs(dat) do
			if v.crit then is_crit = true break end
		end
	end

	local keyD = (is_crit and "Crit" or is_death and "Death" or "") .. "Damage"
	local keyO = (is_crit and "Crit" or is_death and "Death" or "") .. "Outline"

	dat.col1 = dat.col1 or HDN.Colors[keyD]:Copy()
	dat.col2 = dat.col2 or HDN.Colors[keyO]:Copy()

	local colMain, colOut = dat.col1, dat.col2

	anim:LerpColor(colMain, HDN.Colors[keyD], 0.2, 0, 0.3)
	anim:LerpColor(colOut, HDN.Colors[keyO], 0.2, 0, 0.3)

	local x, y
	local do2d = notfocus

	local tx = ("-%d"):format(dat.totalAnim)
	local txW, txH = surface.GetTextSizeQuick(tx, HDN.FontMain)
	local scale = notfocus and 0.4 or 0.5

	local passedFirst = CurTime() - dat.firstDeal
	local passed = CurTime() - dat.lastDmg
	local appearFr = math.max(0, math.Remap(passedFirst, 0, 0.4, 0, 1))

	appearFr = Ease(appearFr, 0.3)
	local rotAng = -Lerp(appearFr, 90, 0)

	if passed > HDN.DisappearTime - HDN.DisappearLen then
		appearFr = math.Remap(passed, HDN.DisappearTime - HDN.DisappearLen, HDN.DisappearTime, 1, 0)
		appearFr = Ease(appearFr, 0.3)
		rotAng = -Lerp(appearFr, 60, 0)
	end

	--[[local bsz = 5
	cam.Start3D()
	render.DrawWireframeBox(hnPos, angle_zero, Vector(-bsz, -bsz, -bsz), Vector(bsz, bsz, bsz), color_white, false)
	cam.End3D()]]

	local cy = state.cury or 0

	if pixvis > 0.25 then
		local vx, vy = vecToScreen(hnPos)
		if not vx then return end

		vx = vx - txW / 2 * scale

		dat.lx, dat.ly = vx, vy

		dat.moveIn = dat.moveIn or (dat.moveOut and CurTime())
		dat.moveOut = nil

		local mpass = dat.moveIn and CurTime() - dat.moveIn or math.huge
		local fr = math.min(1, math.TimeFraction( 0, HDN.MoveLength, mpass ))
		fr = Ease(fr, 0.25)

		x = Lerp(fr, dat.sx or vx, vx)
		y = Lerp(fr, dat.sy or vy, vy)

		-- for animating cury when going back to 3d pos
		state.cury = cy + txH * scale * (1 - fr) * appearFr * 0.875
	else

		dat.moveIn = nil
		dat.moved = true

		dat.sx = ScrW() / 2 + 32
		dat.sy = ScrH() / 2 + txH / 2 * scale

		if dat.lx then
			-- lerp from the last visible position
			dat.moveOut = dat.moveOut or CurTime()
			local mpass = CurTime() - dat.moveOut
			local fr = math.min(1, math.TimeFraction( 0, HDN.MoveLength, mpass ))
			fr = Ease(fr, 0.25)

			x = Lerp(fr, dat.lx, dat.sx)
			y = Lerp(fr, dat.ly, dat.sy + cy )
			state.cury = cy + txH * scale * fr * appearFr * 0.875
		else
			x, y = dat.sx, dat.sy + cy
			state.cury = cy + txH * scale * appearFr * 0.875
		end

		do2d = true
	end

	dat.firstpixvis = false

	local diffVec = tVecs[1]
	diffVec:Set(hnPos)
	diffVec:Sub(ep)
	diffVec:Normalize()

	if not do2d then
		local dot = ev:Dot(diffVec)
		local ang = math.deg(math.acos(dot))

		scale = Lerp(1 - (ang / 45) ^ 0.6, 0.75, 1)
		local distScale = 1 - (math.max(0, ep:Distance(hnPos) - 192) / 768)
		distScale = Lerp(distScale, 0.5, 1)

		scale = Lerp(1 - (ep:Distance(hnPos) / 768), 0.3, 1) * scale

		scale = scale * 0.6
	end

	local shakeDur = is_last_crit and HDN.ShakeLength * 1.3 or HDN.ShakeLength

	local shake = math.max(0, math.Remap(passed, 0, shakeDur, 1, 0)) * (is_last_crit and 12 or 4)

	local freq = is_last_crit and 250 or 100

	local shkX = math.cos(SysTime() * freq * 1.5) * shake / 2
	local shkY = math.sin(SysTime() * freq) * shake

	mx:Reset()

	mx:TranslateNumber(x + shkX, y + shkY)
	mx:SetScaleNumber(scale, scale)

	-- text is bottom-aligned so we add height
	mx:TranslateNumber(0, -txH * (1 - appearFr))
	mx:SetAnglesNumber(0, rotAng)
	mx:TranslateNumber(0, txH * (1 - appearFr))

	tCols[1]:Set(colMain)
	tCols[1].a = Lerp(appearFr, tCols[1].a * 0.33, tCols[1].a)

	tCols[2]:Set(colOut)
	tCols[2].a = Lerp(appearFr, tCols[2].a * 0.1, tCols[2].a)

	DisableClipping(true)
	cam.PushModelMatrix(mx)
		draw.SimpleTextOutlined(tx, HDN.FontMain, 0, 0, tCols[1], 0, 4, 2, tCols[2])
		White()
		--surface.DrawOutlinedRect(-txW / 2, -txH, txW, txH, 2)
	cam.PopModelMatrix()
	DisableClipping(false)

	if passed > 2 then
		return true
	end
end

hook.Add("HUDPaint", "HDN", function()
	if not HDN.EnableSetting:GetValue() then return end

	local state = {}

	draw.EnableFilters()
	for ent, dat in pairs(HDN.Instances) do
		local rem = HDN.DrawEntityNumber(ent, dat, state)
		if rem then HDN.Instances[ent] = nil end
	end

	for ent, dat in pairs(HDN.NPInstances) do
		local rem = HDN.DrawEntityNumber(ent, dat, state, true)
		if rem then HDN.NPInstances[ent] = nil end
	end
	draw.DisableFilters()
end)

hook.Add("PostDrawTranslucentRenderables", "HDN", function(a, b)
	if not HDN.EnableSetting:GetValue() or a or b then return end

	ep, ev = EyePos(), EyeVector()

	for ent, dat in pairs(HDN.Instances) do
		local ok = HDN.DrawEntity(ent, dat)
		--if not ok then HDN.Instances[ent] = nil end
	end
end)