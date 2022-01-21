setfenv(1, _G)
local toDraw = {}
local col = Material("color")
local lmao = CreateMaterial("ltg_kys2", "Eyes", {
	["$basetexture"] = "color/white",
	["$glint"] = "color/white",
	["$iris"] = "color/white",
	["$selfillum"] = "1"
})

local thunderMat = Material("trails/electric")

lmao:SetInt("$selfillum", 1)
local mdlEyes = {}
local replaced = {}

hook.Add("PreDrawSkyBox", "kys_now", function()
	render.SetColorModulation(1, 0.3, 0.3)
end)

local tab = {
	[ "$pp_colour_addr" ] = 0,
	[ "$pp_colour_addg" ] = 0,
	[ "$pp_colour_addb" ] = 0,
	[ "$pp_colour_brightness" ] = 0,
	[ "$pp_colour_contrast" ] = 1,
	[ "$pp_colour_colour" ] = 1,
	[ "$pp_colour_mulr" ] = 0,
	[ "$pp_colour_mulg" ] = 0,
	[ "$pp_colour_mulb" ] = 0
}

local darken_fr = 0

hook.Add("PostDrawSkyBox", "kys_now", function()
	if darken_fr == 0 then return end

	tab["$pp_colour_contrast" ] = 1 - 0.7 * darken_fr
	tab["$pp_colour_brightness" ] = -.5 * darken_fr

	DrawColorModify( tab )
	darken_fr = math.max(0, darken_fr - FrameTime() * 0.3)
end)


local darken = 4.3
local lightning_delay = 4.8
local die_time = 5

local ltg_list = {}

hook.Add("PrePlayerDraw", "kys_now", function(ply, fl)
	if fl ~= --[[bit.bor(STUDIO_TWOPASS, STUDIO_RENDER)]] 0 then return end

	local timeDie = ply:GetNWFloat("kys_now", 0)
	if timeDie == 0 then return end

	ltg_list[ply] = timeDie


	local mdl = ply:GetModel()

	local toRep = mdlEyes[mdl]

	if not toRep then
		local mats = ply:GetMaterials()
		local t = {}
		for k,v in ipairs(mats) do
			if v:find("eye") then
				t[#t + 1] = {k, v}
			end
		end

		mdlEyes[mdl] = t
		toRep = t
	end

	for _, dat in ipairs(toRep) do
		local n = dat[1]
		ply:SetSubMaterial(n - 1, "!ltg_kys2")
	end

	replaced[ply] = true
end)

hook.Add("PostPlayerDraw", "kys_now", function(ply, fl)
	if fl ~= bit.bor(STUDIO_TWOPASS, STUDIO_RENDER) then return end
	if not replaced[ply] then return end

	local toRep = mdlEyes[ply:GetModel()]
	replaced[ply] = false

	for _, dat in ipairs(toRep) do
		local n = dat[1]
		ply:SetSubMaterial(n - 1, "")
	end
end)


local function doLightning(ply, t)
	local startWhen = ply:GetNWFloat("kys_start", 0)
	local passed = CurTime() - startWhen
	local lFr = (passed - lightning_delay) / (die_time - lightning_delay)

	local sinceDie = passed - die_time - 0.2
	local sFr = math.Clamp(sinceDie / 0.4 , 0, 1)
	lFr = math.min(1, lFr)

	if lFr > 0 then
		local pos = ply:GetPos() + ply:OBBCenter()
		local lightStart = ply:GetNWVector("kys_where")
		local beamStart = LerpVector(sFr, lightStart, pos)
		local endPos = LerpVector(lFr, beamStart, pos)

		local startUV = beamStart:Distance(lightStart) / 128 + math.random() * 2
		local endUV = startUV + beamStart:Distance(endPos) / 128
		render.SetMaterial(thunderMat)
		render.DrawBeam(beamStart, endPos,
			32, startUV, endUV, color_white)
	end
end

hook.Add("PostDrawTranslucentRenderables", "kys_now", function(b1, b2)
	if b1 or b2 then return end

	for ply, t in pairs(ltg_list) do
		if CurTime() > t + 2 then ltg_list[ply] = nil continue end

		local tillDie = t - CurTime()
		local dfr = 1 - tillDie / darken
		darken_fr = math.min(1, math.max(dfr, darken_fr))

		doLightning(ply, t)
	end
end)