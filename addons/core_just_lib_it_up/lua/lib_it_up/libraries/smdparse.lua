function smdparse(what, asdata)
	local path = what
	local smd = asdata and what or file.Read(path, "DATA")

	if not smd then
		for i=1, 5 do
			error("Failed to read SMD @ " .. path)
		end
		return false
	end

	local trisStart, trisEnd = smd:find("triangles%c")
	local endStart, endEnd = smd:find("end", trisEnd)

	local tris = smd:sub(trisEnd, endStart)

	local triangles = {}

	local ptrn = "([%w%.%_]+)%c%s*([%d%s%.%-]+)"

	local trinum = 0

	local coord_fields = {
		false, "x", "y", "z",
		"normX", "normY", "normZ",
		"u", "v"
	}

	local scale = 1

	for matName, triData in tris:gmatch(ptrn) do
		--print("tridata is", triData, #triData)

		triangles[matName] = triangles[matName] or {}
		local triTbl = triangles[matName]

		--[[if meshes[matName] then
			meshes[matName]:Destroy()
		end

		meshes[matName] = Mesh()]]

		for triVert in triData:gmatch("%C+") do
			local curPos = 1

			trinum = trinum + 1
			local tri = {}
			triTbl[#triTbl + 1] = tri

			for i=1, #coord_fields do
				local numStart, numEnd = triVert:find("%S+", curPos)
				--print("searching", curPos, numEnd)
				if not numEnd then
					print("Fuck", tris:sub(0, 512), trisEnd, triVert, "|", triData)
				end
				curPos = numEnd + 1
				local data = triVert:sub(numStart, numEnd)
				if coord_fields[i] ~= false then
					tri[coord_fields[i]] = tonumber(data)
				end
			end

			--printf("x: %s, y: %s, z: %s", tri.x, tri.y, tri.z)
		end
	end


	for matName, tris in pairs(triangles) do
		for _, tri in ipairs(tris) do
			tri.pos = Vector(tri.x, tri.y, tri.z) * scale
			--tri.pos:Add(mpos)
			tri.x, tri.y, tri.z = nil, nil, nil

			tri.normal = Vector(tri.normX, tri.normY, tri.normZ)
			tri.normal:Normalize()
			tri.normX, tri.normY, tri.normZ = nil, nil, nil
		end
	end

	return triangles
end