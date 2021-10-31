
--credits to <CODE BLUE>
setfenv(0, _G)
local updating = true --set this to true when fucking with shadows to update the shadow materials with new reloads

BSHADOWS_ID = BSHADOWS_ID or 0
BSHADOWS_ID = BSHADOWS_ID + 1

BSHADOWS = (not updating and BSHADOWS) or {}

local handle = BSHADOWS.Handle or Emitter:extend()
BSHADOWS.Handle = handle
BSHADOWS.Handles = BSHADOWS.Handles or WeakTable("v")

local render = render

--BSHADOWS.RenderTarget = GetRenderTarget("bshadows_original", ScrW(), ScrH())
--BSHADOWS.RenderTarget2 = GetRenderTarget("bshadows_shadow",  ScrW(), ScrH())

BSHADOWS.ShadowMaterial = (not updating and BSHADOWS.ShadowMaterial) or
	CreateMaterial("bshadows" .. BSHADOWS_ID, "UnlitGeneric",{
	["$translucent"] = 1,
	["$vertexalpha"] = 1,
	["$vertexcolor"] = 1,
	["$alpha"] = 1
})

BSHADOWS.ShadowMaterialGrayscale = (not updating and BSHADOWS.ShadowMaterialGrayscale) or
	CreateMaterial("bshadows_grayscale" .. BSHADOWS_ID,"UnlitGeneric",{
	["$translucent"] = 1,
	["$vertexalpha"] = 1,
	["$alpha"] = 1,
	["$color"] = "[0 0 0]",
})

BSHADOWS.ShadowMaterialColorscale = (not updating and BSHADOWS.ShadowMaterialColorscale) or
	CreateMaterial("bshadows_colorscale" .. BSHADOWS_ID,"UnlitGeneric",{
	["$translucent"] = 1,
	["$vertexalpha"] = 1,
	["$alpha"] = 1,
})

local function resStr()
	return ("%dx%d"):format(ScrW(), ScrH())
end

local originalName = "bshadows_original_" .. resStr()
local shadowName = "bshadows_shadow_" .. resStr()

local function resize()
	originalName = "bshadows_original_" .. resStr()
	shadowName = "bshadows_shadow_" .. resStr()

	BSHADOWS.RenderTarget = GetRenderTarget(originalName, ScrW(), ScrH())
	BSHADOWS.RenderTarget2 = GetRenderTarget(shadowName,  ScrW(), ScrH())

	if BSHADOWS.ShadowMaterial then BSHADOWS.ShadowMaterial:SetTexture("$basetexture", BSHADOWS.RenderTarget) end
	if BSHADOWS.ShadowMaterialGrayscale then BSHADOWS.ShadowMaterialGrayscale:SetTexture("$basetexture", BSHADOWS.RenderTarget2) end
	if BSHADOWS.ShadowMaterialColorscale then BSHADOWS.ShadowMaterialColorscale:SetTexture("$basetexture", BSHADOWS.RenderTarget2) end

	for k,v in pairs(BSHADOWS.Handles) do
		v._NeedRegen = true
	end
end

hook.Add("OnScreenSizeChanged", "BSHADOWS_Resize", resize)
resize()

local offsetted = false --is current shadow being offsetted by x,y,w,h args?
local started = 0
local curX, curY = 0, 0
local curW, curH
local realW, realH
local CurRT, ShadowRT

local useRT

function BSHADOWS.UseRT(rt)
	if isstring(rt) then rt = BSHADOWS.RTs[rt] end
	assert(type(rt) == "ITexture")
	useRT = rt
end

BSHADOWS.RTs = BSHADOWS.RTs or {}

local spreadSize = 32

function handle:Initialize(name, rt, mat, w, h)
	self.Name, self.RT, self.Mat = name, rt, mat
	self.W, self.H = w, h

	BSHADOWS.Handles[name] = self
end

function handle:SetGenerator(fn)
	assert(isfunction(fn))

	self._Generator = fn
end


function handle:Paint(x, y, w, h)
	if self._NeedRegen and self._LastArgs then
		self:CacheShadow(unpack(self._LastArgs))
		self._NeedRegen = nil
	end

	surface.SetDrawColor(255, 255, 255)
	surface.SetMaterial(self.Mat)

	local ratW, ratH = w / self.W, h / self.H

	surface.DrawTexturedRect(x - spreadSize * ratW, y - spreadSize * ratH,
		w + spreadSize * 2 * ratW, h + spreadSize * 2 * ratH)
end

local err = GenerateErrorer("BShadows")

function handle:CacheShadow(int, spr, blur, color, color2)
	if not self._Generator then
		error("handle has no generator")
		return
	end

	self._LastArgs = {int, spr, blur, color, color2}

	self:_Begin()
	print("CacheShadow called")
		xpcall(self._Generator, err, self, self.W, self.H)
	self:_End(int, spr, blur, color, color2)
end

function handle:_Begin()
	BSHADOWS.UseRT(self.RT)
	BSHADOWS.BeginShadow()
end

function handle:_End(intensity, spread, blur, color, color2)
	BSHADOWS.CacheShadow(intensity, spread, blur,
		255, 0, 0, color, color2)
end

function handle:Offset(x, y)
	return x and (x * self.W / realW), y and (y / realH * self.H)
end

BSHADOWS.GenerateCache = function(name, w, h)
	local key = name .. w .. "x" .. h
	local rt, mat = draw.GetRTMat("bshad_cust_" .. name, w + spreadSize * 2, h + spreadSize * 2, "UnlitGeneric")
	BSHADOWS.RTs[key] = handle:new(key, rt, mat, w, h)
	return BSHADOWS.RTs[key]
end

BSHADOWS.BeginShadow = function(x, y, w, h)
	realW, realH = ScrW(), ScrH()
	curW, curH = w or realW, h or realH

	local rt1 = useRT or BSHADOWS.RenderTarget
	local rt2 = BSHADOWS.RenderTarget2

	if not rt1 or not rt2 then print("failed to get Rt for the shadow or somethin?") return end

	CurRT = rt1
	ShadowRT = rt2

	if useRT then
		-- clean out the entire RT cuz if we only push a fraction of it,
		-- only that fraction will be cleared out
		render.PushRenderTarget(useRT)
			render.Clear(0, 0, 0, 0, true)
		render.PopRenderTarget()

		render.PushRenderTarget(rt2)
			render.Clear(0, 0, 0, 0, true)
		render.PopRenderTarget()

		-- only allow drawing on a fraction of the rt
		render.PushRenderTarget(useRT, spreadSize, spreadSize,
			useRT:GetMappingWidth() - spreadSize * 2, useRT:GetMappingHeight() - spreadSize * 2)
	else
		render.PushRenderTarget(rt1)

		render.SetScissorRect(0, 0, 0, 0, false) -- mighty annoying
		render.OverrideAlphaWriteEnable(true, true)
			render.Clear(0, 0, 0, 0, true)
		render.OverrideAlphaWriteEnable(false, false)
	end

	if x and y then
		offsetted = true
		curX, curY = x, y
	end

	started = started + 1

	cam.Start2D()
	--Now leave the rest to the user to draw onto the surface
end

BSHADOWS.ScissorRect = {}

BSHADOWS.SetScissor = function(x, y, w, h)
	BSHADOWS.ScissorRect.x = x
	BSHADOWS.ScissorRect.y = y
	BSHADOWS.ScissorRect.w = w
	BSHADOWS.ScissorRect.h = h
end

local screct = BSHADOWS.ScissorRect

local function scissor()
	render.SetScissorRect(screct.x, screct.y, screct.x + screct.w, screct.y + screct.h, true)
end

local function unscissor()
	render.SetScissorRect(0, 0, 0, 0, false)
end


BSHADOWS.CacheShadow = function(intensity, spread, blur, opacity, direction, distance, color, color2)
	opacity = opacity or 255
	direction = direction or 0
	distance = distance or 0

	local rt = useRT
	useRT = nil
	render.CopyRenderTargetToTexture(ShadowRT) -- copy contents onto a temporary RT: shadow

	if blur > 0 then
		local sprX, sprY = 0, 0

		if istable(spread) then
			sprX, sprY = spread[1], spread[2]
		else
			sprX, sprY = spread, spread
		end

		render.OverrideAlphaWriteEnable(true, true)
			render.BlurRenderTarget(ShadowRT, sprX, sprY, blur) -- then blur it
		render.OverrideAlphaWriteEnable(false, false)
	end

	render.PopRenderTarget()

	local shmat = BSHADOWS.ShadowMaterialGrayscale

	if color or color2 then
		shmat = BSHADOWS.ShadowMaterialColorscale
	end

	shmat:SetTexture("$basetexture", ShadowRT)

	if color then
		local vc = Vector(color.r, color.g, color.b) --nO cOloR mEtatAblE

		shmat:SetVector("$color", vc)               --this is a weird ass shader which adds something like a...halo, i guess
													--it really looks like a halo more than a shadow
		if not color2 then
			shmat:SetUndefined("$color2")
		end
	end

	if color2 then
		local vc = Vector(color2.r, color2.g, color2.b)
		shmat:SetVector("$color2", vc)  --color2 is more "color of the shadow" than "color of the halo"

		if not color then shmat:SetUndefined("$color") end
	end

	if color or color2 then
		shmat:Recompute()
	end

	local mat = BSHADOWS.ShadowMaterial
	mat:SetTexture("$basetexture", CurRT)
	shmat:SetFloat("$alpha", opacity / 255)

	render.SetMaterial(shmat)
	render.PushRenderTarget(rt)
	render.Clear(0, 0, 0, 0, true, true)
		render.OverrideAlphaWriteEnable(true, true)

		for i=1, intensity do
			-- Bro
			render.DrawScreenQuad()
		end

		render.OverrideAlphaWriteEnable(false, false)
	render.PopRenderTarget()
	started = started - 1
	cam.End2D()
end

local radar = false

--This will draw the shadow, and mirror any other draw calls the happened during drawing the shadow
BSHADOWS.EndShadow = function(intensity, spread, blur, opacity, direction, distance, _shadowOnly, color, color2)

	if radar then
		print("ended shadow:", debug.Trace())
	end

	--Set default opcaity
	opacity = opacity or 255
	direction = direction or 0
	distance = distance or 0

	--Copy this render target to the other
	render.CopyRenderTargetToTexture(ShadowRT)

	--Blur the second render target
	if blur > 0 then
		local sprX, sprY = 0, 0

		if istable(spread) then
			sprX, sprY = spread[1], spread[2]
		else
			sprX, sprY = spread, spread
		end

		render.OverrideAlphaWriteEnable(true, true)
			render.BlurRenderTarget(ShadowRT, sprX, sprY, blur)
		render.OverrideAlphaWriteEnable(false, false)

	end

	--First remove the render target that the user drew
	if started then render.PopRenderTarget() end

	local shmat = BSHADOWS.ShadowMaterialGrayscale	--the actual shadow material
	local mat = BSHADOWS.ShadowMaterial 			--the material on which the user has drawn

	if color or color2 then
		shmat = BSHADOWS.ShadowMaterialColorscale
	end

	shmat:SetTexture("$basetexture", ShadowRT)

	if color then
		local vc = Vector(color.r, color.g, color.b) --nO cOloR mEtatAblE

		shmat:SetVector("$color", vc)				--this is a weird ass shader which adds something like a...halo, i guess
													--it really looks like a halo more than a shadow
		if not color2 then
			shmat:SetUndefined("$color2")
		end
	end

	if color2 then
		local vc = Vector(color2.r, color2.g, color2.b)
		shmat:SetVector("$color2", vc)	--color2 is more "color of the shadow" than "color of the halo"

		if not color then
			shmat:SetVector("$color", Vector())
		end
	end

	if color or color2 then
		shmat:Recompute()
	end

	--Work out shadow offsets
	local xOffset = math.sin(math.rad(direction)) * distance
	local yOffset = math.cos(math.rad(direction)) * distance

	shmat:SetFloat("$alpha", opacity / 255)

	--first draw the shadow

	render.SetMaterial(shmat)

	local x, y = xOffset + curX, yOffset + curY

	for i = 1, math.ceil(intensity) do
			-- https://github.com/Facepunch/garrysmod-issues/issues/4635
		if screct.x then scissor() end
			render.DrawScreenQuadEx(x, y, curW or ScrW(), curH or ScrH())
	end

	if screct.x then unscissor() end

	--then whatever the user has drawn
	-- render.OverrideAlphaWriteEnable(true, false)

	if not _shadowOnly then
		mat:SetTexture("$basetexture", CurRT)

		render.SetMaterial(mat)
		if screct.x then scissor() end
			render.DrawScreenQuadEx(curX, curY, curW, curH)
	end

	-- https://github.com/Facepunch/garrysmod-issues/issues/4635
	-- restore any scissors that were ruined due to this issue
	if screct.x then render.Rescissor() end

	if offsetted then
		cam.End2D()
		started = started - 1
		curX = 0
		curY = 0

		offsetted = false
		return
	end

	if started > 0 then cam.End2D() started = started - 1 end
end