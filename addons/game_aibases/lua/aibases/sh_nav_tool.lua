StartTool("AINavTool")

AIBases.Builder = AIBases.Builder or {}
local bld = AIBases.Builder
bld.NWNav = Networkable("aibuild_nav")

TOOL.Category = "AIBases"
TOOL.Name = "NavTool"
TOOL.AINavTool = true

if SERVER then
	util.AddNetworkString("aib_navrecv")
end

bld.NavClass = bld.NavClass or Emitter:extend()

function bld.NavClass:Initialize(cnav, ply)
	if cnav then
		self.handle = cnav
		self.id = cnav:GetID() -- uniq.Seq("NavClass")
		self.ply = ply
	end
end

function bld.NavClass:NW()
	local dat = self.handle:GetExtentInfo()

	bld.NWNav:SetTable(self.id, {
		ply = self.ply,
		min = dat.lo, max = dat.hi,
		--adj = self.handle:GetAdjacentAreas()
	})
end

function bld.NavClass:Remove()
	if IsValid(self.handle) then self.handle:Remove() end
	bld.NWNav:Set(self.id, nil)
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

	print("serialize")
	local navext = self.handle:GetExtentInfo()
	print("got extend")
	local adj = self.handle:GetAdjacentAreas()
	print("got adjacent", #adj)
	for k,v in pairs(adj) do
		print("getting id of", k, v)
		adj[k] = v:GetID()
	end

	local dat = {
		min = navext.lo, max = navext.hi,
		adj = adj, -- e?
		id = self.id
	}

	print("json-ifying")
	return util.TableToJSON(dat)
end

function bld.NavClass:Load(dat)
	local new = self:new()
	new.dat = dat
	new.id = dat.id

	return new
	-- self.handle = navmesh.CreateNavArea(dat.min, dat.max)
end

function bld.NavClass:Spawn()
	if not self.dat then error("no data to create from!") return end
	if IsValid(self.handle) then self.handle:Remove() end

	local dat = self.dat
	self.handle = navmesh.CreateNavArea(dat.min, dat.max)
	self.id = self.handle:GetID()
end

function bld.NavClass:PostSpawn(navs, lnavs)
	if not self.dat then error("no data to create from!") return end
	local dat = self.dat

	for k,v in pairs(dat.adj) do
		if not lnavs[v] and not navs[v] then
			printf("!! failed to find nav ID:`%d` to connect to %d !!", v, self.handle:GetID())
			continue
		end

		if lnavs[v] then
			self.handle:ConnectTo(lnavs[v].handle)
		elseif navs[v] then
			self.handle:ConnectTo(navs[v])
		end
	end
end

local function add(ow, cnav)
	assert(IsPlayer(ow))

	bld.NW[ow:UserID()] = bld.NW[ow:UserID()] or {}
	bld.NW[ow:UserID()][e] = id
	bld.NW:SetTable(ow:UserID(), bld.NW[ow:UserID()])
end

function TOOL:StartNetwork()
	local navs = navmesh.GetAllNavAreas()

	function networkList(s, e)
		net.Start("aib_navrecv", false)
			net.WriteUInt(s, 32)
			net.WriteUInt(e, 32)

			for i=s, e do
				local cn = navs[i]
				net.WriteUInt(cn:GetID(), 24)
				local dat = cn:GetExtentInfo()
				net.WriteVector(dat.lo)
				net.WriteVector(dat.hi)
			end

		net.Broadcast()
	end

	for i=1, #navs, 3000 do
		timer.Create("nw_nav" .. i, i / 5000, 1, function()
			networkList(i, math.min(#navs, i + 3000))
			print("sent " .. i + 3000 .. "/" .. #navs)
		end)
	end
end

function TOOL:Reload()
	if not AIBases.Builder.Allowed(self:GetOwner()) or not IsFirstTimePredicted() then return end

	print("reload", Realm(), self.ConnectingNav)
	if self.ConnectingNav then
		net.Start("aib_navrecv")
			net.WriteUInt(2, 4)
			net.WriteUInt(self.ConnectingNav.id, 32)
		net.SendToServer()

		self:UnselectNav()
		return
	end

	if SERVER and not self:GetOwner():KeyDown(IN_ATTACK2) then
		self:StartNetwork(self:GetOwner())
	end
end

local fuck = Vector()

local function grabNav(nav, tr, curDist)
	local int = util.IntersectRayWithPlane(tr.StartPos, tr.Normal, nav.center, vector_up)
	if not int then return false end

	local min, max = nav.min, nav.max

	local dist = int:DistToSqr(tr.StartPos)
	if dist > curDist then return false end

	local in_box = min.x <= int.x and int.x <= max.x and
		min.y <= int.y and int.y <= max.y and
		min.z <= int.z and int.z <= max.z

	if not in_box then return false end

	if int:DistToSqr(tr.HitPos) > 16 and not tr.HitPos:WithinAABox(min, max) then return false end

	-- debugoverlay.Sphere(int, 4, 4, 4)
	--debugoverlay.SweptBox(vector_origin, vector_origin, min, max, angle_zero, 2, Colors.Red)

	return dist, int
end

function TOOL:GrabNavAim(tr)
	local bDist, bNav = math.huge

	-- map navs
	for k,v in pairs(AIBases.Navs) do
		local d = grabNav(v, tr, bDist)
		if not d then continue end

		if d < bDist then
			bDist = d
			bNav = v
		end
	end

	-- custom navs
	for k,v in pairs(AIBases.Builder.NWNav:GetNetworked()) do
		local d, pos = grabNav(v, tr, bDist)
		if not d then continue end

		if d < bDist then
			bDist = d
			bNav = v
		end
	end


	return bNav
end

function TOOL:UnselectNav()
	if not self.ConnectingNav then return end
	self.ConnectingNav.col = nil
	self.ConnectingNav.force = nil
	self.ConnectingNav = false
end

function TOOL:RightClick(tr)
	if SERVER or not IsFirstTimePredicted() then return end

	if self.ConnectingNav then
		self:UnselectNav()
		sfx.CheckOut()
		return
	end

	sfx.CheckIn()
	local bNav = self:GrabNavAim(tr)

	if bNav then
		bNav.col = Colors.Golden
		bNav.force = true
		self.ConnectingNav = bNav
	end
end

function TOOL:LeftClick(tr)
	if SERVER or not IsFirstTimePredicted() then return end

	if self.ConnectingNav then
		local nav = self.ConnectingNav
		local nav2 = self:GrabNavAim(tr)
		if not nav2 then sfx.Fail() return end

		self:UnselectNav()
		sfx.SetFinish()

		print("IDs:", nav.id, nav2.id)

		net.Start("aib_navrecv")
			net.WriteUInt(1, 4)
			net.WriteUInt(nav.id, 32)
			net.WriteUInt(nav2.id, 32)
		net.SendToServer()
		return
	end

	local am = GetTool("AreaMark", LocalPlayer())

	am:JustMark()

	am:Once("ZoneConfirmed", "mark", function(_, _, a, b)
		RunConsoleCommand("gmod_tool", "AINavTool")

		net.Start("aib_navrecv")
			net.WriteUInt(0, 4)
			net.WriteVector(a)
			net.WriteVector(b)
		net.SendToServer()
	end)

	RunConsoleCommand("gmod_tool", "AreaMark")
end

EndTool()


if CLIENT then
	concommand.Add("aib_remove", function()
		if not AIBases.Builder.Allowed(CachedLocalPlayer()) then return end

		local tool = GetTool("AINavTool", CachedLocalPlayer())
		if not tool then return end

		local nav = tool:GrabNavAim(CachedLocalPlayer():GetEyeTrace())
		if not nav then return end

		net.Start("aib_navrecv")
			net.WriteUInt(3, 4)
			net.WriteUInt(nav.id, 32)
		net.SendToServer()
		print("removing nav", nav)
	end)
end
--[[
if ( nav_show_nodes.GetBool() )
	{
		for ( CNavNode *node = CNavNode::GetFirst(); node != NULL; node = node->GetNext() )
		{
			if ( m_editCursorPos.DistToSqr( *node->GetPosition() ) < 150*150 )
			{
				node->Draw();
			}
		}
	}
]]

AIBases.Navs = AIBases.Navs or {}
local renderDist = 150 * 150

local cursor = 1
local vis = {}

local lastGrab, lastAim = CurTime(), nil
local tps = 1 / 10

hook.Add("PostDrawTranslucentRenderables", "NavTool", function()
	local lp = CachedLocalPlayer()
	local tool = lp:GetTool()
	if not tool or not tool.AINavTool then return end

	local tg = lp:GetActiveWeapon()
	if not tg:IsValid() or tg:GetClass() ~= "gmod_tool" then return end

	local upd = math.floor(FrameTime() * 80000)
	local to = math.min(#AIBases.Navs, cursor + upd)
	local mp = EyePos()
	local vec = EyeVector()
	local tr = lp:GetEyeTrace()

	for i=cursor, to do
		local v = AIBases.Navs[i]
		if bld.NWNav:GetNetworked()[i] then continue end
		if v.force then vis[v] = i continue end

		local inter = util.IntersectRayWithPlane(mp, vec, v.max, vector_up)
		local dist = math.min(v.min:DistToSqr(mp), v.center:DistToSqr(mp), v.max:DistToSqr(mp))

		local int = inter and v.center:DistToSqr(inter) < v.rad + 32 and tr.HitPos:DistToSqr(inter) < v.rad
		vis[v] = (dist < renderDist or int) and i or nil
	end

	if to == #AIBases.Navs then
		cursor = 1
	else
		cursor = to
	end

	local conNav

	if tool.ConnectingNav then
		local getNew = CurTime() - lastGrab > tps
		local to = (getNew and tool:GrabNavAim(tr) or lastAim or tool:GrabNavAim(tr))
		lastAim = to
		lastGrab = getNew and CurTime() or lastGrab
		conNav = to
		conNav.onceCol = Colors.Sky
		render.DrawLine(tool.ConnectingNav.center, (to and to.center) or tr.HitPos, to and Colors.Sky or Colors.Reddish)
	end

	for v, _ in pairs(vis) do
		if not AIBases.Navs[_] then vis[v] = nil continue end

		render.DrawWireframeBox(vector_origin, angle_zero, v.min, v.max, v.onceCol or v.col, true)
		debugoverlay.Text(v.center, v.id, 0.1, true)
		v.onceCol = nil
	end
end)

if CLIENT then
	net.Receive("aib_navrecv", function(len, p)
		local s, e = net.ReadUInt(32), net.ReadUInt(32)

		if s == 1 then table.Empty(AIBases.Navs) end

		for i=s, e do
			local id = net.ReadUInt(24)
			local min, max = net.ReadVector(), net.ReadVector()

			if bld.NWNav:GetNetworked()[i] then continue end

			AIBases.Navs[i] = {
				min = min,
				max = max,
				center = (min + max) / 2,
				id = id,
			}
			local t = AIBases.Navs[i]
			local bmin, bmax = (t.min - t.center), (t.max - t.center)
			t.rad = math.max(bmin:Length() ^ 2, bmax:Length() ^ 2)
		end
	end)
end
