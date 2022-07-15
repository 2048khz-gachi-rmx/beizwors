-- this really shouldn'tve been an issue

local spotCache = {}

local function hashVec(vec)
	return ("%.f %.f %.f"):format(vec:Unpack())
end

local function unhashVec(hash)
	return Vector(hash)
end

function ENT:FindSpots( tbl )
	local zones = self:BW_GetBase()
	if zones then zones = zones:GetZones() end

	tbl = tbl or {}

	tbl.pos			= tbl.pos			or self:WorldSpaceCenter()
	tbl.radius		= tbl.radius		or 1000
	tbl.stepdown	= tbl.stepdown		or 20
	tbl.stepup		= tbl.stepup		or 20
	tbl.type		= tbl.type			or 'hiding'

	-- Use a path to find the length
	local path = Path("Follow")

	-- Find a bunch of areas within this distance
	local areas = navmesh.Find( tbl.pos, tbl.radius, tbl.stepdown, tbl.stepup )

	local found = {}

	-- In each area
	for _, area in pairs( areas ) do

		-- get the spots
		local spots

		if ( tbl.type == 'hiding' ) then
			spots = area:GetHidingSpots()
		end

		for k, vec in pairs(spots) do
			local key = hashVec(vec)
			local inBase = false

			if spotCache[key] == nil and zones then
				for _, zone in pairs(zones) do
					local mins, maxs = zone:GetBounds()
					if vec:WithinAABox(mins, maxs) then
						inBase = true
						break
					end
				end

				spotCache[key] = inBase
			else
				inBase = not zones or spotCache[key]
			end

			if inBase then
				-- Work out the length, and add them to a table
				path:Invalidate()
				path:Compute( self, vec, 1 ) -- TODO: This is bullshit - it's using 'self.pos' not tbl.pos
				table.insert( found, { vec, path:GetLength() } )
			end
		end
	end

	return found
end

local function sorter(a, b)
	return a[2] < b[2]
end

function ENT:FindSpot(type, options)
	local spots = self:FindSpots( options )
	if ( !spots || #spots == 0 ) then return end

	if ( type == "near" ) then
		table.sort(spots, sorter)
		return spots[1][1]
	end

	if ( type == "far" ) then
		table.sort(spots, sorter)
		return spots[#spots][1]
	end

	-- random
	return spots[ math.random( 1, #spots ) ].vector
end