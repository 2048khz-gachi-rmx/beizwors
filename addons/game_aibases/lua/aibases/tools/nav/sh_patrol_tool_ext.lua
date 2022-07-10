local bld = AIBases.Builder
bld.PNW = Networkable("aibuild-patrol")
local nw = bld.PNW

if CLIENT then
	bld.Patrols = bld.Patrols or {}

	function TOOL:Opt_PatrolLeftClick(tr)
		local ent = tr.Entity

		if not IsValid(ent) or not ent.IsAIBaseBot then
			chat.AddText(Color(250, 100, 100), "thats not a bot brother")
			return
		end

		self.SelectedBot = ent
		bld.Patrols[ent] = bld.Patrols[ent] or {}

		net.Start("patrol-aib")
			net.WriteUInt(0, 4)
			net.WriteEntity(ent)
		net.SendToServer()
	end

	function TOOL:Opt_PatrolRightClick(tr)
		if not IsValid(self.SelectedBot) then return end

		local bot = self.SelectedBot
		local patr = bld.Patrols[bot]

		table.insert(patr, tr.HitPos)
	end

	function TOOL:Opt_SelectPatrol(f)
		if IsValid(self.phold) then
			self.phold.Y = f.ModeHolder.Y + f.ModeHolder:GetTall() + 8 + 32
			self.phold:MoveTo(0, f.ModeHolder.Y + f.ModeHolder:GetTall() + 8, 0.3, 0, 0.3)
			self.phold:PopInShow()
			return
		end

		local phold = vgui.Create("InvisPanel", f)
		phold:SetSize(f:GetWide(), 80)
		phold:SetPos(0, f.ModeHolder.Y + f.ModeHolder:GetTall() + 8 + 32)
		phold:MoveTo(0, f.ModeHolder.Y + f.ModeHolder:GetTall() + 8, 0.3, 0, 0.3)
		phold:PopIn()
		phold:DockPadding(8, 0, 8, 0)
		self.phold = phold

		hook.Add("PostDrawTranslucentRenderables", "PatrolRender", function() self:PatrolRender() end)

		local tool = self

		local fic = vgui.Create("FIconLayout", phold)
		fic:Dock(TOP)
		fic:SetTall(36)
		fic.NoDraw = true

		local rewind = fic:Add("FButton")
		rewind:SetText("Remove the last pos")
		rewind:SetSize(128, 28)
		rewind:SetColor(Colors.Golden)
		rewind:PickFont()

		function rewind:DoClick()
			local e = tool.SelectedBot
			if not IsValid(e) then return end

			if bld.Patrols[e] then
				table.remove(bld.Patrols[e])
			end
		end

		local wipe = fic:Add("FButton")
		wipe:SetText("Clear temporary")
		wipe:SetSize(128, 28)
		wipe:SetColor(Colors.Reddish)
		wipe:PickFont()

		function wipe:DoClick()
			local e = tool.SelectedBot
			if not IsValid(e) then return end

			bld.Patrols[e] = {}
		end

		local reset = fic:Add("FButton")
		reset:SetText("Copy server's")
		reset:SetSize(128, 28)
		reset:SetColor(Colors.Reddish)
		reset:PickFont()

		function reset:DoClick()
			local e = tool.SelectedBot
			if not IsValid(e) then return end

			local cur = nw:Get(e)
			bld.Patrols[e] = table.Copy(cur or {})
		end

		local save = fic:Add("FButton")
		save:SetText("Save to server")
		save:SetSize(128, 28)
		save:SetColor(Colors.Sky)
		save:PickFont()

		function save:DoClick()
			local e = tool.SelectedBot
			if not IsValid(e) then return end

			
			local cur = bld.Patrols[e]

			net.Start("patrol-aib")
				net.WriteUInt(1, 4)
				net.WriteEntity(e)
				net.WriteUInt(#cur, 8)
				for k,v in ipairs(cur) do
					net.WriteVector(v)
				end
			net.SendToServer()
		end
	end

	function TOOL:Opt_DeselectPatrol(f)
		if IsValid(self.phold) then self.phold:PopOut() self.phold = nil end
		hook.Remove("PostDrawTranslucentRenderables", "PatrolRender")
	end

	hook.Remove("PostDrawTranslucentRenderables", "PatrolRender")

	local rbow = Color(0, 0, 0)

	local sphereMat = Material("models/props_combine/portalball001_sheet")
	local tempMat = Material("models/props_combine/tprings_globe")
	local beam = Material("trails/physbeam")

	local up = Vector(0, 0, 1)
	local t1, t2 = Vector(), Vector()

	local function paintRoute(t, trailCol, height)
		for k,v in pairs(t) do
			render.DrawSphere(v, 4, 8, 8, color_white)
		end

		local o = t[1]

		if o and #t > 1 then
			render.SetMaterial(beam)
			for k,v in pairs(t) do
				t1:CSet(up):CMul(height or 8):CAdd(v)
				t2:CSet(up):CMul(height or 8):CAdd(o)

				local dist = o:Distance(v)
				render.DrawBeam(t1, t2, 6, CurTime() / 6, CurTime() / 6 + (dist / 256), trailCol)
				o = v
			end
		end
	end

	function TOOL:PatrolRender()
		local e = self.SelectedBot
		if not IsValid(e) then return end

		local cur = nw:Get(e)

		rbow:SetHSV(CurTime() * 120, 1, 1)
		render.DrawWireframeBox(e:GetPos(), e:GetAngles(), e:OBBMins(), e:OBBMaxs(), rbow, true)

		if cur then
			render.SetMaterial(sphereMat)

			paintRoute(cur, Colors.Green, 16)
		end

		if bld.Patrols[e] then
			render.SetMaterial(tempMat)

			paintRoute(bld.Patrols[e])
		end
	end
else

end