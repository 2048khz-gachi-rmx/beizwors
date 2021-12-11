local RTs = MoarPanelsRTs or muldim:new()
MoarPanelsRTs = RTs

local mats = MoarPanelsRTMats or {}
MoarPanelsRTMats = mats

local function CreateRT(name, w, h)

	return GetRenderTargetEx(
		name,
		w,
		h,
		RT_SIZE_OFFSCREEN,
		MATERIAL_RT_DEPTH_SEPARATE, 	-- https://github.com/Facepunch/garrysmod-issues/issues/5039
		2, 	--texture filtering, the enum doesn't work
		0,	-- no hdr
		IMAGE_FORMAT_RGBA8888		-- i guess?
	)

end

local fmt = "%s_%d_%d"
function draw.GetRT(name, w, h)
	local rt
	if not w or not h then error("error #2 or #3: expected width and height, received nothin'") return end

	name = fmt:format(name, w, h)

	if not RTs[name] then
		rt = CreateRT(name, w, h)
		RTs[name] = rt
	else
		rt = RTs[name]
	end

	return rt
end

function draw.GetRTMat(name, w, h, shader)
	local rt = draw.GetRT(name, w, h)
	name = fmt:format(name, w, h)

	local mat = mats[name]
	if not mat then

		mat = CreateMaterial(name, shader or "UnlitGeneric", {
			["$basetexture"] = rt:GetName(),
			["$translucent"] = 1,
			["$vertexalpha"] = 1,
			["$vertexcolor"] = 1,
		})

		mats[name] = mat
	end

	return rt, mat
end

function draw.RenderOntoRT(rt, w, h, fn)

	render.PushRenderTarget(rt)
		render.OverrideAlphaWriteEnable(true, true)

			render.ClearDepth()
			render.Clear(0, 0, 0, 0)

			cam.Start2D()
			local ok, err = pcall(fn, w, h, rt)
			cam.End2D()

		render.OverrideAlphaWriteEnable(false)
	render.PopRenderTarget()
end

function draw.RenderOntoMaterial(name, w, h, func, rtfunc, matfunc, pre_rt, pre_mat, has2d, x, y)

	local rt
	local mat

	if not RTs[name] then

		rt = CreateRT(name, w, h)

		mat = CreateMaterial(name, "UnlitGeneric", {
			["$translucent"] = 1,
			["$vertexalpha"] = 1,
			["$vertexcolor"] = 1,
		})

		local m = muldim()
		RTs[name] = m
		m:Set(rt, w, h)
		m:Set(1, "Number")

		mats[name] = mat

	else
		local rtm = RTs[name]
		local cached = rtm:Get(w, h)

		if cached then
			rt = cached
		else --new W and H aren't equal, so recreate the RT

			local id = rtm:Get("Number")
			rtm:Set(id + 1, "Number")
			rt = CreateRT(name .. id, w, h)
			rtm:Set(rt, w, h)
		end

		mats[name] = mats[name] or CreateMaterial(name, "UnlitGeneric", {
			["$translucent"] = 1,
			["$vertexalpha"] = 1,
			["$vertexcolor"] = 1,
		})

		mat = mats[name]
	end

	rt = pre_rt or rt
	mat = pre_mat or mat

	mat:SetTexture("$basetexture", rt:GetName())

	render.PushRenderTarget(rt)

		render.OverrideAlphaWriteEnable(true, true)

			render.ClearDepth()
			render.Clear(0, 0, 0, 0)

			if not has2d then cam.Start2D() end
				local ok, err = pcall(func, w, h, rt)


			if rtfunc and ok then
				local ok, keep = pcall(rtfunc, rt)
				if ok and keep == false then

					render.PopRenderTarget()
					render.OverrideAlphaWriteEnable(false)
					if not has2d then cam.End2D() end

					return
				end
			end

			if not has2d then cam.End2D() end

		render.OverrideAlphaWriteEnable(false)

	render.PopRenderTarget()



	if matfunc and ok then
		matfunc(mat)
	end

	if not ok then
		error("RenderOntoMaterial got an error while drawing!\n" .. err)
		return
	end

	return mat

end