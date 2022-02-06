if SERVER then
	FInc.FromHere("client/huds/*", FInc.CLIENT)
	return
end

local MODULE = BaseWars.HUD or {}
BaseWars.HUD = MODULE

local draw = draw

local backcol = Color(40, 40, 40)
local hdcol = Color(30, 30, 30)

local alpha = 0

local default_w, default_h = 180, 55

local lastpos = Vector()
local lastToScreen = {x = 0, y = 0, visible = false}
local lastent

local vm = Matrix()
local anims = Animatable("bw_basssehud")

local minDist = 64
local defaultMaxDist = 200
local maxDist = defaultMaxDist

local minScale = 0.3
local fadeStart = 0.6
local fadeEnd = minScale

-- is this the first frame that the HUD is present?
local initialFrame = false
local lastPainter = nil

local function remap(cur, min, max)
	return (math.max(cur, min) - min) / (max - min)
end

local function updateToscreen(force)
	if force then
		cam.Start3D()
	end

	lastToScreen = lastpos:ToScreen()

	if force then
		cam.End3D()
	end
end

hook.Add("PostDrawTranslucentRenderables", "StructureInfoToScreen", updateToscreen)

local b = bench("bw_hud", 600)

local trOut = {}

local trEnd = Vector()
local eyePos = Vector()

local trParams = {
	start = nil,
	endpos = trEnd,

	maxs = vector_origin,
	mins = vector_origin,
	filter = {},

	output = trOut,
}


local function DrawStructureInfo()
	local me = CachedLocalPlayer()
	local ep = EyePos()
	eyePos:Set(ep)

	local av = me:GetAimVector()
	av:Mul(512)

	trEnd:Set(ep)
	trEnd:Add(av)

	trParams.start = ep
	trParams.filter[1] = me

	local trace = util.TraceHull(trParams)

	--b:Close():print()

	local ent = trace.Entity:IsValid() and trace.Entity

	local valid = not not ent -- and ent.IsBaseWars
	local dist = lastpos:Distance(trace.StartPos)

	if not valid then
		anims:To("Alpha", 0, 0.25, 0, 0.2)
	else
		local wep = me:GetActiveWeapon()
		local class = (IsValid(wep) and wep:GetClass())
				-- not holding a physgun = 250,
				-- holding an entity with the physgun = 140,
				-- just have the physgun out = 230
		local to = (class ~= 'weapon_physgun' and 250) or me:GetPhysgunningEntity() and 80 or 230

		local ep = ent:LocalToWorld(ent:OBBCenter())

		dist = ep:Distance(eyePos)
		lastent = ent

		name = ent.PrintName or "wat"

		local should, distAppear, pntr, posr = hook.Run("BW_ShouldPaintStructureInfo", ent, dist)
		maxDist = distAppear or defaultMaxDist

		if should then
			lastPainter = pntr
			lastpos = posr and posr(ent, trace, ep) or ep

			anims:To("Alpha", to, 0.15, 0, 0.3)
		else
			anims:To("Alpha", 0, 0.3, 0, 0.3)
		end
	end

	alpha = anims.Alpha or 0

	backcol.a = alpha
	hdcol.a = alpha

	if not IsValid(lastent) then initialFrame = true return end

	local frac = remap(dist, minDist, maxDist)
	local intScale = Lerp(1 - frac, 0, 1)
	local scale = math.max(intScale, minScale)

	local scAlpha = remap(math.min(intScale, fadeStart), fadeEnd, fadeStart)
	alpha = alpha * scAlpha

	if alpha < 1 then initialFrame = true return end

	local ts = lastToScreen
	if not ts.visible then initialFrame = true return end

	local x, y = ts.x, ts.y 	--middle of the window's XY
	local sx, sy = x, y 		--top left XY

	local w, h = anims.Width or default_w, anims.Height or default_h

	vm:Identity()

	vm:SetScaleNumber(scale, scale)
	vm:SetTranslationNumber(x, y)
	vm:TranslateNumber(-w/2, -h/2)

	sx, sy = sx - w/2 * scale, sy - h/2 * scale

	local amult = surface.GetAlphaMultiplier()

	if isfunction(lastPainter) then
		render.PushFilterMin(TEXFILTER.ANISOTROPIC)
		cam.PushModelMatrix(vm)
		surface.SetAlphaMultiplier(amult * (alpha / 255))
		DisableClipping(true)
			local ok, err = xpcall(lastPainter, GenerateErrorer("BWHUD"), lastent, ent, anims, initialFrame)
			DisableClipping(false)
		surface.SetAlphaMultiplier(amult)
		cam.PopModelMatrix()
		render.PopFilterMin()

		lastPainter = nil
	end

	initialFrame = false
end

function MODULE.PaintFrame(w, h, headerH)
	local round = math.min(6, headerH / 2)

	draw.RoundedBoxEx(round, 0, 0, w, headerH, hdcol, true, true)
	draw.RoundedBoxEx(6, 0, 0 + headerH, w, h - headerH, backcol, nil, nil, true, true)
end

MODULE._Ents = {}

function MODULE.StoreEnt(name, ent)
	if not ent or not ent:IsValid() then return end
	MODULE._Ents[name] = ent
end

function MODULE.GetEnt(name)
	if not MODULE._Ents[name] or not MODULE._Ents[name]:IsValid() then return end
	return MODULE._Ents[name]
end

--[==================================[
		Death Cooldown HUD
--]==================================]
local vm2 = Matrix()

local ela
local dead = false

local left

local CreateElastic

CreateElastic = function(func, off)
	ela = Animations.InElastic(0.8, off, func, function()
		if not dead then ela = nil return end
		CreateElastic(func, 0.2)
	end, 0.7, 1.4, 2)
end

local rot = 0
local txw

local function DrawDeathCoolDown()
	local me = LocalPlayer()
	if me:Alive() then dead = false return end

	dead = true

	local t = me:GetRespawnTime()
	if not t then return end

	local dt = me:GetDeathTime()
	if not dt then return end

	left = t - CurTime()

	local frac = left / (t - dt)
	frac = math.min(1, frac)

	local leftfrac = 1 - frac

	draw.NoTexture()
	surface.SetDrawColor(60, 60, 60)

	render.SetStencilEnable(true)

		render.ClearStencil()

		render.SetStencilWriteMask(0xFF)
		render.SetStencilTestMask(0xFF)

		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)

		render.SetStencilCompareFunction(STENCIL_NEVER)
		render.SetStencilFailOperation(STENCIL_REPLACE)

		render.SetStencilReferenceValue(1)

			draw.Circle(ScrW()/2, ScrH() - 192, 56, 32, leftfrac*100)

		render.SetStencilReferenceValue(2)

			draw.Circle(ScrW()/2, ScrH() - 192, 32, 32)

		render.SetStencilCompareFunction(STENCIL_NOTEQUAL)

			draw.MaterialCircle(ScrW()/2, ScrH() - 192, 92)

		render.SetStencilReferenceValue(1)

		render.SetStencilCompareFunction(STENCIL_EQUAL)

			surface.SetDrawColor(color_white)
			draw.MaterialCircle(ScrW()/2, ScrH() - 192, 92)

	render.SetStencilEnable(false)

	if not ela then
		CreateElastic(function(fr)
			rot = fr*360
		end, math.abs(left)%1 - 0.1)
	end

	local a = 255

	if left-1 <= 0 then
		a = (math.max(left, 0)^4)*255
	end

	surface.SetFont("OSB32")
	local tw, th = surface.GetTextSize(tostring(math.floor(left)))
	txw = L(txw, tw, 5)

	surface.SetTextPos(0, 0)
	vm2:SetAngles(Angle(0, rot, 0))
	vm2:SetTranslation(Vector(ScrW()/2, ScrH() - 192))
	vm2:Translate(Vector((tw-txw)/2 - tw/2, -th/2, 0))



	cam.PushModelMatrix(vm2)
		local ok, err = pcall(function()
			surface.SetTextColor(255, 255, 255, a)
			surface.DrawText(math.floor(left))
		end)
	cam.PopModelMatrix()
end


local function PaintStuff()
	DrawStructureInfo()

	DrawDeathCoolDown()
end

hook.Add("HUDPaint", "StructureInfoPaint", PaintStuff)

include("client/huds/painter_ext.lua")
FInc.FromHere("client/huds/*.lua", FInc.CLIENT)

hook.Run("BW_HUDLoaded")