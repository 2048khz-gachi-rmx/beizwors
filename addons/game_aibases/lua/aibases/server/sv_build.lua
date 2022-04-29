local ENTITY = FindMetaTable("Entity")

AIBases.Builder = AIBases.Builder or {}
local bld = AIBases.Builder

function ENTITY:GetAIBuilders()
	return bld.EntTracker:GetOrSet(self)
end

util.AddNetworkString("AIBuild_Add")

net.Receive("AIBuild_Add", function(len, ply)
	if not bld.Allowed(ply) then print("unallowed AIBuild", ply) return end

	local min, max = net.ReadVector(), net.ReadVector()
	local center = (min + max) / 2
	min = min - center
	max = max - center

	local woll = ents.Create("aib_wall")
	woll:SetPos(center)

	woll:Spawn()
	woll:InitPhys(min, max)
	woll:Activate()

	_brs = woll
	AIBases.Builder.AddBrick(ply, woll, AIBases.BRICK_BOX)
end)

concommand.Add("aibases_savelayout", function(ply, _, arg)
	if not bld.Allowed(ply) then return end

	local name = arg[1]
	if not arg[1] then print("give a name tard") return end

	local overwrite = arg[2]
	if file.Exists("aibases/layouts/" .. name .. ".dat", "DATA") and overwrite ~= "yes" then
		ply:ChatPrint("layout already exists: make second arg 'yes' to confirm overwrite")
		print("layout already exists: make second arg 'yes' to confirm overwrite")
		return
	end

	print("saving layout `" .. name .. "`...")

	local layout = AIBases.BaseLayout:new(name)


	local tool = GetTool("AIBaseBuild", ply)
	if not tool then print("no tool") return end

	local bents = tool:GetList()
	printf("%d bricks", table.Count(bents))

	local brs = {}
	local uid = 0

	for ent, id in pairs(bents) do
		if not IsValid(ent) then
			AIBases.Builder.AddBrick(ply, ent, nil)
			continue
		end

		local base = AIBases.IDToBrick(id)
		local brick = base:Build(ent)
		brick.Data.uid = uid
		if ent.Brick then ent.Brick.uid = uid end

		layout:AddBrick(brick)
		uid = uid + 1
		--brs[#brs + 1] = brick
	end

	for k,v in pairs(layout.Bricks) do
		v:PostBuild(layout.Bricks)
	end

	local out = layout:Serialize() --

	file.CreateDir("aibases/layouts")
	file.Write("aibases/layouts/" .. name .. ".dat", out)
end)

bld.Navs = bld.Navs or {}

net.Receive("aib_navrecv", function(len, ply)
	if not bld.Allowed(ply) then return end

	local mode = net.ReadUInt(4)
	print('recv mode', mode)
	if mode == 15 then
		-- request fullupdate
		ply:GetTool("AINavTool"):StartNetwork(ply)
		return
	end

	if mode == 0 then
		local min, max = net.ReadVector(), net.ReadVector()
		--local cnav = navmesh.CreateNavArea(min, max)
		local lnav = bld.NavClass:new(false, ply)
		lnav:CreateNew(min, max)

		bld.Navs[ply] = bld.Navs[ply] or {}
		bld.Navs[ply][#bld.Navs[ply] + 1] = lnav

		lnav:NW()
	elseif mode == 1 then
		local id = net.ReadUInt(32)
		local id2 = net.ReadUInt(32)

		local navs = navmesh.GetAllNavAreas()
		local lkup = {}
		for k,v in pairs(navs) do lkup[v:GetID()] = v end

		if not lkup[id] then
			print("no nav 1: halting.", id)
			return
		end

		if not lkup[id2] then
			print("no nav 2: halting.", id2)
			return
		end

		print("connecting", id, id2)
		lkup[id]:ConnectTo(lkup[id2])
		print("connected", id, id2)
	elseif mode == 2 then
		-- claim a nav for lua
		local id = net.ReadUInt(32)
		local nav = navmesh.GetNavAreaByID(id)
		if not IsValid(nav) then print("didnt find nav with id", id) return end

		if bld.Navs[id] and bld.Navs[id]:IsValid() then
			print("already claimed in lua")
			bld.Navs[id]:NW()
			return
		end

		print("claiming nav for lua", nav)
		local lnav = bld.NavClass:new(nav, ply)
		bld.Navs[ply] = bld.Navs[ply] or {}
		bld.Navs[ply][#bld.Navs[ply] + 1] = lnav
		bld.Navs[id] = lnav

		lnav:NW()
	elseif mode == 3 then
		-- delete a nav

		local id = net.ReadUInt(32)
		local nav = navmesh.GetNavAreaByID(id)
		if IsValid(nav) then
			nav:Remove()
			print("deleted cnav")
		end

		if bld.Navs[ply] then
			for k,v in pairs(bld.Navs[ply]) do
				if v.id == id then
					v:Remove()
					bld.Navs[v.id] = nil
					bld.Navs[ply][k] = nil
					print("deleted lua nav")
				end
			end
		end

		print("delete done; check above")
	elseif mode == 4 then
		-- add a hiding spot
		local id = net.ReadUInt(32)
		local bits = net.ReadUInt(8)
		local where = net.ReadVector()

		local nav = navmesh.GetNavAreaByID(id)
		if not IsValid(nav) then printf("no nav with id %s", id) return end
		printf("adding hiding spot %d to %s", bits, where)
		nav:AddHidingSpot(where, bits)
		if bld.Navs[id] then
			bld.Navs[id]:NW()
		end
	end
end)

concommand.Add("aib_claim", function(ply, _, arg)
	if not bld.Allowed(ply) then return end

	local name = arg[1]
	if not arg[1] then print("give a name tard") return end

	local lay = _G[name]
	if not lay or not istable(lay) or not lay.LuaNavs then print("not nav") return end

	for k,v in pairs(lay.LuaNavs) do
		bld.Navs[ply] = bld.Navs[ply] or {}
		bld.Navs[ply][#bld.Navs[ply] + 1] = v
		bld.Navs[v.id] = v
		v.ply = ply

		v:NW()
	end
end)

concommand.Add("aib_mark", function(ply, _, arg)
	if not bld.Allowed(ply) then return end

	local name = arg[1]
	if not arg[1] then print("give a name tard") return end

	local lay = _G[name]
	if not lay or not istable(lay) or not lay.Bricks then print("no bricks") return end

	for id, bs in pairs(lay.Bricks) do
		for _, brick in pairs(bs) do
			if not brick.Ent then continue end
			AIBases.Builder.AddBrick(ply, brick.Ent, id)
		end
	end
end)

GetNav = navmesh.GetNavAreaByID

concommand.Add("aib_removeall", function(ply)
	if not bld.Allowed(ply) then return end

	if bld.Navs[ply] then
		for k,v in pairs(bld.Navs[ply]) do
			v:Remove()
			bld.Navs[v.id] = nil
			bld.Navs[ply][k] = nil
			print("deleted lua nav")
		end

		bld.Navs[ply] = {}
	end
end)

function PLAYER:MarkAllWIP()
	for k,v in ipairs(ents.FindByClass(("*prop_physics*"))) do
		if v.Brick then
			AIBases.Builder.AddBrick(self, v, AIBases.BRICK_PROP)
		end
	end

	for k,v in ipairs(ents.FindByClass(("aib_wall"))) do
		AIBases.Builder.AddBrick(self, v, AIBases.BRICK_BOX)
	end

	for k,v in ipairs(ents.FindByClass(("aib_bot"))) do
		AIBases.Builder.AddBrick(self, v, AIBases.BRICK_ENEMY)
	end

	for k,v in ipairs(ents.FindByClass(("bw_morph_door"))) do
		AIBases.Builder.AddBrick(self, v, AIBases.BRICK_DOOR)
	end
end