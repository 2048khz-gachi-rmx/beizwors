-- no not the nsfw fucking mats
local customMats = {}

MoarPanelsMats._ReloadAll = function()
	for k,v in pairs(customMats) do
		MoarPanelsMats[k] = nil
		draw.GetMaterial(v[1], v[2], v[3])
	end
end

MoarPanelsMats._YeetAll = function()
	for k,v in pairs(customMats) do
		MoarPanelsMats[k] = nil
	end
end

-- callback: 1st arg is material, 2nd arg is boolean: was the material loaded from cache?
								-- (aka it was already loaded; if its a first load it's false)
local function GetOrDownload(url, name, flags, cb)
	if url == "-" or name == "-" then return false end
	if not name then ErrorNoHalt("GetOrDownload: No name!\n") return end

	local key = name:gsub("%.%w+$", "") .. (flags or "")
	if key == "_YeetAll" or key == "_ReloadAll" then
		ErrorNoHalt("GetOrDownload: Attempt to download a material with a reserved name!\n")
	end

	local mat = MoarPanelsMats[key]

	name = name:gsub("%(.+%)", "")

	if not mat or (mat.failed and mat.failed ~= url) then 	--mat was not loaded

		mat = {}
		MoarPanelsMats[key] = mat

		if file.Exists("hdl/" .. name, "DATA") then 		--mat existed on disk: load it in

			local cmat = Material("data/hdl/" .. name, flags or "smooth ignorez")

			mat.mat = cmat

			MatsBack[cmat] = mat

			mat.w = cmat:Width()
			mat.h = cmat:Height()

			mat.flags = flags or ""
			mat.path = "data/hdl/" .. name

			mat.fromurl = url
			customMats[key] = {url, name, flags}
			if cb then cb(mat.mat, false) end
		else 												--mat did not exist on disk: download it then load it in

			mat.downloading = true
			customMats[key] = {url, name, flags}

			hdl.DownloadFile(url, name or "unnamed.dat", function(fn)
				mat.downloading = false
				local cmat = Material(fn, flags or "smooth ignorez")
				mat.mat = cmat
				MatsBack[cmat] = mat

				mat.w = cmat:Width()
				mat.h = cmat:Height()
				mat.flags = flags or ""
				mat.path = fn

				if cb then cb(mat.mat, false) end

			end, function(err)

				mat.mat = Material("materials/icon16/cancel.png")
				mat.failed = url
				mat.downloading = false
				errorf("Failed to download! URL: %s\n Error: %s", url, err)
			end)

		end

	else --mat was already preloaded
		if mat.mat then MatsBack[mat.mat] = mat end

		if cb then cb(mat.mat, true) end
	end

	return mat, not mat.failed and mat.mat
end

draw.GetMaterial = GetOrDownload

function draw.GetMaterialInfo(mat)
	return MatsBack[mat] or MoarPanelsMats[mat]
end