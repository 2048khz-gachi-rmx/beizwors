StartTool("AINavTool")

AIBases.Builder = AIBases.Builder or {}
local bld = AIBases.Builder
_G.bld = bld
bld.NWNav = Networkable("aibuild_nav")
bld.NW = Networkable("aibuild")

if CLIENT then
	bld.NWNav:On("NetworkedVarChanged", "fill", function(self, key, old, new)
		if istable(new) then
			new.center = (new.min + new.max) / 2
			new.id = key
		end
	end)
end

AIBases.MarkTool = TOOL
local TOOL = AIBases.MarkTool

TOOL.Category = "AIBases"
TOOL.Name = "NavTool"
TOOL.AINavTool = true

if SERVER then
	util.AddNetworkString("aib_navrecv")
end

bld.NavClass = bld.NavClass or Emitter:extend()

local function hashVec(vec)
	return ("%.f %.f %.f"):format(vec:Unpack())
end

local function unhashVec(hash)
	return Vector(hash)
end

local function navHideSpots(nav)
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
		spots = navHideSpots(self.handle),
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

function TOOL:StartNetwork()
	local navs = navmesh.GetAllNavAreas()

	function networkList(s, e)
		net.Start("aib_navrecv", false)
			net.WriteUInt(s, 32)
			net.WriteUInt(e, 32)

			for i=s, e do
				local cn = navs[i]
				net.WriteUInt(cn:GetID(), 18)
				local dat = cn:GetExtentInfo()
				net.WriteVector(dat.lo)
				net.WriteVector(dat.hi)

				local bybits = navHideSpots(cn)

				local hasSpots = not table.IsEmpty(bybits)
				net.WriteBool(hasSpots)

				if hasSpots then
					net.WriteUInt(table.Count(bybits), 8)
					for bit, data in pairs(bybits) do
						net.WriteUInt(bit, 8)
						net.WriteUInt(#data, 8)
						for bits, vec in pairs(data) do
							net.WriteVector(vec)
						end
					end
				end
			end

		net.Send(self:GetOwner())
	end

	if self:GetOwner():GetWIPNavs() then
		for k,v in pairs(self:GetOwner():GetWIPNavs()) do
			if not v:IsValid() then self:GetOwner():GetWIPNavs()[k] = nil continue end
			v:NW()
		end
	end

	local len = 0
	local s = 1

	for i=1, #navs do
		s = s or i
		len = len + 1

		if i - s > 2000 then
			local s2 = s
			timer.Create("nw_nav" .. s, i / 5000, 1, function()
				networkList(s2, i)
				printf("2 sent %d - %d", s2, i)
			end)

			s = i
		end
	end

	timer.Create("nw_nav_finale", #navs / 5000 + 0.2, 1, function()
		networkList(s, #navs)
		printf("3 sent %d - %d", s, #navs)
	end)

	--[[for i=1, #navs, 2000 do
		timer.Create("nw_nav" .. i, i / 5000, 1, function()
			networkList(i, math.min(#navs, i + 2000))
			print("sent " .. i + 2000 .. "/" .. #navs)
		end)
	end]]
end

function TOOL:Reload()
	--[[if not AIBases.Builder.Allowed(self:GetOwner()) or not IsFirstTimePredicted() then return end

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
	end]]
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

	if self.CurMode then
		local name = self.CurMode[1]
		if not self["Opt_" .. name .. "RightClick"] then
			printf("No method: %s", "Opt_" .. name .. "RightClick")
			return
		end

		self["Opt_" .. name .. "RightClick"] (self, tr)
	end

	--[[if self.ConnectingNav then
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
	end]]
end

function TOOL:LeftClick(tr)
	if SERVER or not IsFirstTimePredicted() then return end

	if self.CurMode then
		local name = self.CurMode[1]
		if not self["Opt_" .. name .. "LeftClick"] then
			printf("No method: %s", "Opt_" .. name .. "LeftClick")
			return
		end

		self["Opt_" .. name .. "LeftClick"] (self, tr)
	end

	--[[if self.ConnectingNav then
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

	RunConsoleCommand("gmod_tool", "AreaMark")]]
end


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
	local to = math.min(table.maxn(AIBases.Navs), cursor + upd)
	local mp = EyePos()
	local vec = EyeVector()
	local tr = lp:GetEyeTrace()

	for i=cursor, to do
		local v = AIBases.Navs[i]
		if not v then continue end

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

		if s == 1 then table.Empty(AIBases.Navs) table.Empty(vis) end

		for i=s, e do
			local id = net.ReadUInt(18)
			local min, max = net.ReadVector(), net.ReadVector()

			if bld.NWNav:GetNetworked()[i] then continue end

			AIBases.Navs[i] = {
				min = min,
				max = max,
				center = (min + max) / 2,
				id = id,
				spots = {}
			}

			local t = AIBases.Navs[i]
			local bmin, bmax = (t.min - t.center), (t.max - t.center)
			t.rad = math.max(bmin:Length() ^ 2, bmax:Length() ^ 2)


			local hasSpots = net.ReadBool()

			if hasSpots then
				local bitsAmt = net.ReadUInt(8)

				for i=1, bitsAmt do
					local bits, vecAmt = net.ReadUInt(8), net.ReadUInt(8)
					t.spots[bits] = t.spots[bits] or {}
					for vi=1, vecAmt do
						table.insert(t.spots[bits], net.ReadVector())
					end
				end
			end
		end
	end)

	function TOOL:GetInstance()
		local lp = LocalPlayer()
		if not lp or not lp:IsValid() then return false end

		local tool = lp:GetTool()
		local wep = tool and tool:GetWeapon()
		if not tool or not tool.AINavTool or lp:GetActiveWeapon() ~= wep then return false end

		return tool
	end

	local modes = {
		{"Mark", "New NavArea"},
		{"Claim", "Claim & Connect NavAreas"},
		{"Spot", "New Spot"},
	}

	function TOOL:Opt_ClaimLeftClick(tr)
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

		local bNav = self:GrabNavAim(tr)

		if bNav then
			bNav.col = Colors.Golden
			bNav.force = true
			self.ConnectingNav = bNav
			sfx.CheckIn()
		end
	end

	function TOOL:Opt_ClaimRightClick(tr)
		if self.ConnectingNav then
			self:UnselectNav()
			sfx.CheckOut()
			return
		end

		local nav = self:GrabNavAim(tr)
		if not nav then
			sfx.Failure()
			print("no nav")
			return
		end

		net.Start("aib_navrecv")
			net.WriteUInt(2, 4)
			net.WriteUInt(nav.id, 32)
		net.SendToServer()
		sfx.SetIn()
	end

	function TOOL:Opt_MarkLeftClick(tr)
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

	function TOOL:Opt_SelectMark(f)

	end

	function TOOL:Opt_DeselectMark(f)

	end

	function TOOL:Opt_SelectClaim(f)

	end

	function TOOL:Opt_DeselectClaim(f)
		self:UnselectNav()
	end

	local CUR_BITS = 0
	local spots = {
		[1] = "Covered",
		[2] = "Sniper",
		[4] = "Vantage",
		[8] = "Exposed",
		[16] = "[Unused 1]",
		[32] = "[Unused 2]",
		[64] = "[Unused 3]",
		[128] = "[Unused 4]",
	}

	function TOOL:Opt_SelectSpot(f)
		if IsValid(self.spotHolder) then
			self.spotHolder.Y = f.ModeHolder.Y + f.ModeHolder:GetTall() + 8 + 32
			self.spotHolder:MoveTo(0, f.ModeHolder.Y + f.ModeHolder:GetTall() + 8, 0.3, 0, 0.3)
			self.spotHolder:PopInShow()
			return
		end

		local spotHolder = vgui.Create("InvisPanel", f)
		spotHolder:SetSize(f:GetWide(), 32)
		spotHolder:SetPos(0, f.ModeHolder.Y + f.ModeHolder:GetTall() + 8 + 32)
		spotHolder:MoveTo(0, f.ModeHolder.Y + f.ModeHolder:GetTall() + 8, 0.3, 0, 0.3)
		spotHolder:PopIn()
		self.spotHolder = spotHolder

		local spotBtns = {}

		local spotW = (f:GetWide() - 16 - (table.Count(spots) - 1) * 4) / table.Count(spots)
		local x = 8

		local function recalcBits()
			CUR_BITS = 0
			for k,v in pairs(spotBtns) do
				CUR_BITS = CUR_BITS + (v.Active and k or 0)
			end
		end

		for k,v in pairs(spots) do
			local btn = vgui.Create("FButton", spotHolder)
			spotBtns[k] = btn

			btn:SetSize(spotW, 32)
			btn:SetPos(x, 0)
			btn:SetText(v)
			btn:SetFont("OS20")

			x = x + spotW + 4

			function btn:DoClick()
				self.Active = not self.Active
				self:SetColor(self.Active and Colors.Sky or Colors.Button)
				recalcBits()
			end

			if bit.band(CUR_BITS, k) > 0 then
				btn.Active = true
				btn:SetColor(btn.Active and Colors.Sky or Colors.Button)
			end
		end

		local sphereMat = Material("models/props_combine/portalball001_sheet")
		hook.Add("PostDrawTranslucentRenderables", "CrossSpot", function()
			if not CachedLocalPlayer():GetTool() or not CachedLocalPlayer():GetTool().AINavTool then return end
			render.SetMaterial(sphereMat)
			render.DrawSphere(ply:GetEyeTrace().HitPos,
			 	3, 16, 16,
			 	Colors.Sky)
		end)

		hook.Add("DrawLuaNav", "Spots", function(nav)
			--print("drawing lua nav", nav, table.Count(nav.spots))
			render.SetMaterial(sphereMat)
			for bits, dat in pairs(nav.spots) do
				for _, pos in pairs(dat) do
					render.DrawSphere(pos, 3, 16, 16, color_white)
				end
			end
		end)

		hook.Add("HUDPaint", "HideSpot", function()
			if not CachedLocalPlayer():GetTool() or not CachedLocalPlayer():GetTool().AINavTool then return end

			local lines = {"Spots:"}

			for k,v in pairs(spots) do
				if bit.band(CUR_BITS, k) > 0 then
					lines[#lines + 1] = v
				end
			end

			local y = ScrH() / 2 - #lines * draw.GetFontHeight("OSB24") / 2
			for k,v in pairs(lines) do
				local x = k == 1 and 32 or 48
				local f = k == 1 and "OSB24" or "OS20"
				local tw, th = draw.SimpleText(v, f, ScrW() / 2 + x, y, color_white)
				y = y + th
			end
		end)
	end

	function TOOL:Opt_DeselectSpot(f)
		hook.Remove("PostDrawTranslucentRenderables", "CrossSpot")
		hook.Remove("HUDPaint", "HideSpot")
		hook.Remove("DrawLuaNav", "Spots")
		if IsValid(self.spotHolder) then
			self.spotHolder:MoveBy(0, 24, 0.3, 0, 0.3)
			self.spotHolder:PopOutHide()
		end
	end

	function TOOL:Opt_SpotLeftClick(tr)
		local bNav = self:GrabNavAim(tr)

		if not bNav then
			sfx.Failure()
			return
		end

		local pos = tr.HitPos

		local bits = CUR_BITS

		net.Start("aib_navrecv")
			net.WriteUInt(4, 4)
			net.WriteUInt(bNav.id, 32)
			net.WriteUInt(bits, 8)
			net.WriteVector(pos)
		net.SendToServer()
		sfx.CheckIn()
	end

	function TOOL:Opt_SpotRightClick(tr)
		
	end

	function TOOL:ShowOptions(dat)
		if IsValid(dat[1]) then
			dat[1]:Remove()
		end

		local tool = self
		local f = vgui.Create("FFrame")
		dat[1] = f
		dat[2] = self

		f:SetSize(ScrW() * 0.4, ScrH() * 0.25)
		f:CenterHorizontal()
		f.Y = ScrH()
		f:MoveTo(f.X, ScrH() - f:GetTall() - 32, 0.2, 0, 0.3)
		f:SetMouseInputEnabled(true)
		f:MakePopup()
		f:SetKeyboardInputEnabled(false)
		f:PopIn()
		RestoreCursorPosition()

		function f:PrePaint()
			DisableClipping(true)
				surface.SetDrawColor(0, 0, 0, 180)
				surface.DrawRect(-ScrW(), -ScrH(), ScrW() * 2, ScrH() * 2)
			DisableClipping(false)
		end

		local sync = vgui.Create("FButton", f)
		sync:SetSize(f:GetWide() * 0.3, 36)
		sync:SetPos(8, f:GetTall() - sync:GetTall() - 8)
		sync:SetColor(Colors.Golden)
		sync:SetIcon(Icons.Reload)
		sync:SetText("Resync navmesh")

		function sync:DoClick()
			net.Start("aib_navrecv")
			net.WriteUInt(15, 4)
			net.SendToServer()
		end

		local modeHolder = vgui.Create("InvisPanel", f)
		modeHolder:SetSize(f:GetWide(), 32)
		modeHolder:SetPos(4, f.HeaderSize + 4)
		f.ModeHolder = modeHolder

		local modeBtns = {}
		local ac = false
		local x = 8
		local modeW = (f:GetWide() - 16 - (table.Count(modes) - 1) * 8) / table.Count(modes)

		for k,v in pairs(modes) do
			local btn = vgui.Create("FButton", modeHolder)
			modeBtns[k] = btn

			btn:SetSize(modeW, 32)
			btn:SetPos(x, 0)
			btn:SetText(v[2])
			btn:SetFont("OSB20")

			x = x + modeW + 8

			function btn:DoClick()
				if self.Active then return end

				if ac then
					ac:Deselect()
				end

				self.Active = true
				self:SetColor(self.Active and Colors.Sky or Colors.Button)
				tool.CurMode = v
				ac = self

				if tool["Opt_Select" .. v[1]] then
					tool["Opt_Select" .. v[1]] (tool, f)
				end
			end

			function btn:Deselect()
				if not self.Active then return end

				self.Active = false
				self:SetColor(self.Active and Colors.Sky or Colors.Button)
				if tool["Opt_Deselect" .. v[1]] then
					tool["Opt_Deselect" .. v[1]] (tool, f)
				end
			end

			if tool.CurMode and tool.CurMode[1] == v[1] then btn:DoClick() end
		end
	end

	function TOOL:HideOptions(dat)
		if not IsValid(dat[1]) then return end
		local f = dat[1]
		f:PopOut(0.2)
		f:MoveTo(f.X, ScrH(), 0.2, 0, 3.3, function()
			f:Remove()
		end)

		RememberCursorPosition()
		f:SetMouseInputEnabled(false)

		dat[1] = nil
	end

	local curTool = AIBases.Builder.Menus or {} -- { pnl, tool }
	AIBases.Builder.Menus = curTool

	if IsValid(curTool[1]) then curTool[1]:Remove() end

	local bnd = Bind("aib_navs")
	bnd:SetHeld(false)

	local MENU_KEY = KEY_R

	bnd:SetDefaultKey(MENU_KEY)
	bnd:SetKey(MENU_KEY)
	bnd:SetDefaultMethod(BINDS_HOLD)
	bnd:SetMethod(BINDS_HOLD)

	bnd:On("Activate", 1, function(self, ply)
		local tool = TOOL:GetInstance()
		if not tool then return end
		tool:ShowOptions(curTool)
	end)

	bnd:On("Deactivate", 1, function(self, ply)
		if not curTool[2] then return end
		curTool[2]:HideOptions(curTool)
	end)
end

EndTool()

local PLAYER = FindMetaTable("Player")
function PLAYER:GetWIPNavs()
	return bld.Navs[self] --bld.NWNav:GetNetworked()[self]
end