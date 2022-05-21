local bld = AIBases.Builder
bld.NavClass = bld.NavClass or Emitter:extend()

local function hashVec(vec)
	return ("%.f %.f %.f"):format(vec:Unpack())
end

local function unhashVec(hash)
	return Vector(hash)
end

function bld.NavHideSpots(nav)
	local spots = {}
	local bybits = {}

	for i=0, 7 do
		local bits = bit.lshift(1, i)
		local sp = nav:GetHidingSpots(bits)
		for _, vec in ipairs(sp) do
			spots[hashVec(vec)] = bit.bor(spots[hashVec(vec)] or 0, bits)
		end
	end

	for k,v in pairs(spots) do
		bybits[v] = bybits[v] or {}
		table.insert(bybits[v], unhashVec(k))
	end

	return bybits
end

bld.NavToLuaTbl = bld.NavToLuaTbl or {}
bld.LuaNavs = bld.LuaNavs or {}

local CNavArea = FindMetaTable("CNavArea")

if SERVER then
	function CNavArea:GetUID()
		if bld.NavToLuaTbl[self] then
			return bld.NavToLuaTbl.uid
		end

		return self:GetID()
	end
end

function bld.NavToLua(nav)
	if not isnumber(nav) then nav = nav:GetID() end
	local lua = bld.NavToLuaTbl[nav]
	local han = lua and IsValid(lua.handle)
	return han and lua
end

function bld.NavClass:Initialize(cnav, ply)
	if cnav then
		self.handle = cnav
		self.id = cnav:GetID() -- uniq.Seq("NavClass")

		bld.NavToLuaTbl[cnav:GetID()] = self
	end

	self.uid = uniq.Random(16)
	self.ply = ply
end

function bld.NavClass:CreateNew(min, max)
	local cnav = navmesh.CreateNavArea(min, max)
	self.handle = cnav
	self.id = cnav:GetID()

	bld.NavToLuaTbl[self.id] = self
end

function bld.NavClass:IsValid()
	return IsValid(self.handle)
end

function bld.NavClass:NW()
	if not IsValid(self) then return end

	local dat = self.handle:GetExtentInfo()

	bld.NWNav:SetTable(self.id, {
		ply = self.ply,
		uid = self.uid,
		min = dat.lo, max = dat.hi,
		spots = bld.NavHideSpots(self.handle),
		--adj = self.handle:GetAdjacentAreas()
	})
end

function bld.NavClass:Remove()
	if IsValid(self.handle) then
		bld.NavToLuaTbl[self.handle:GetID()] = nil
		self.handle:Remove()
	end
	bld.NWNav:Set(self.id, nil)
	bld.LuaNavs[self.uid] = nil
	bld.Navs[self.id] = nil
	-- this will break sequential removals
	--[[if self.ply then
		table.RemoveByValue(self.ply:GetWIPNavs(), self)
	end]]
end

function bld.NavClass:UpdateID()
	-- use only when re-serializing
	self.id = self.handle:GetID()
end

function bld.NavClass:Serialize()
	if not self.handle:IsValid() then
		error("tard how is handle not valid")
		return
	end

	local navext = self.handle:GetExtentInfo()
	local adj = self.handle:GetAdjacentAreas()

	for k,v in pairs(adj) do
		local ln = bld.NavToLua(v)
		if ln then
			ln:UpdateID()
		end

		print("serialize: connecting to", ln and "luanav" or "cnav", ln and ln.uid or v:GetID(), v)
		-- if we're connected to a luanav, use its' uid (string)
		-- otherwise use the id (number)
		adj[k] = ln and ln.uid or v:GetID()
	end

	local spots = navHideSpots(self.handle)

	local dat = {
		min = navext.lo, max = navext.hi,
		adj = adj, -- e?
		id = self.id,
		spots = spots,
		uid = self.uid,
	}

	return util.TableToJSON(dat)
end

function bld.NavClass:Load(dat)
	local new = self:new()
	new.dat = dat
	new.id = dat.id
	new.uid = dat.uid

	return new
	-- self.handle = navmesh.CreateNavArea(dat.min, dat.max)
end

function bld.NavClass:Spawn()
	if not self.dat then error("no data to create from!") return end
	if IsValid(self.handle) then self.handle:Remove() end

	local dat = self.dat
	self.handle = navmesh.CreateNavArea(dat.min, dat.max)
	self.id = self.handle:GetID()

	bld.NavToLuaTbl[self.id] = self
end

function bld.NavClass:PostSpawn(navs, lnavs)
	if not self.dat then error("no data to create from!") return end
	local dat = self.dat

	for k,v in pairs(dat.adj) do
		if isstring(v) then
			-- uid: find luanav
			if not lnavs[v] then
				printf("!! failed to find lua nav with ID:`%s` to connect to %d !!", v, self.id)
				continue
			end

			self.handle:ConnectTo(lnavs[v].handle)
		else
			if not navs[v] then
				printf("!! failed to find Cnav with ID:`%s` to connect to %d !!", v, self.id)
				continue
			end

			self.handle:ConnectTo(navs[v])
		end
	end

	if dat.spots then
		for bits, vecs in pairs(dat.spots) do
			print("restoring spots", bits)
			for k,v in pairs(vecs) do
				self.handle:AddHidingSpot(v, bits)
			end
		end
	end
end