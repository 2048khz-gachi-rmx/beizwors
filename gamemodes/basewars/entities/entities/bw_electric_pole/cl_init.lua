include("shared.lua")
AddCSLuaFile("shared.lua")



PowerPoles = PowerPoles or {}
local poles = PowerPoles

function ENT:OnConnectionChange(id, old, new)
	local me = BWEnts[self]

	if not IsValid(new) then 
		new = nil 
	end 

	local key = (id < 9 and "Generators") or (id < 24 and "Electronics") or "Grid"
	me[key][id + 1] = new

	if id < 24 and id >= 9 and IsValid(new) then 
		me.ThrowLightning[new] = {t = CurTime(), start = self:GetPos(), ["end"] = new:GetPos(), dist = self:GetPos():Distance(new:GetPos())}
	end

end

local blue = Color(40, 120, 250)
local green = Color(80, 200, 80)

local curtip = ""
local popup = false
local hovd

function ENT:CreateBaseScroll(pnl, name, icon)

	local scr = vgui.Create("FScrollPanel", pnl)
	scr:SetSize(400, 250)

	scr.GradBorder = true
	scr.BackgroundColor = Color(60, 60, 60)
	scr:GetCanvas():DockPadding(0, 8, 0, 8)
	scr.Shadow = {intensity = 3, blur = 1}

	function scr:PostPaint(w, h)
		surface.DisableClipping(true)

			BSHADOWS.BeginShadow()

				local x, y = self:LocalToScreen(0, 0)

				local tw, th = draw.SimpleText(name, "OSB36", x + w/2, y - 18, color_white, 1, 1)

				surface.SetDrawColor(255, 255, 255)

				surface.DrawMaterial(icon.url, icon.name, x + w/2 - tw/2 - 36, y-18 - 16, 32, 32)

			BSHADOWS.EndShadow(3, 2, 2, 255)

		surface.DisableClipping(false)	

	end

	return scr
end

function ENT:CreateGeneratorsScroll(pnl, me)

	local scr = self:CreateBaseScroll(pnl, "Generators", {
		url = "https://i.imgur.com/poRxTau.png", 
		name = "electricity.png"
	})

	scr.X = 425 - 400
	scr.Y = pnl.CircleY

	for k,v in ValidPairs(me.Generators) do 
		local f = scr:Add("InvisPanel")
		f:Dock(TOP)
		f:DockMargin(0, 0, 0, 8)
		f:SetTall(64)

		local name = v.PrintName or "wtf"
		local gens = "+" .. (v.PowerGenerated or -1337) .. "PW"

		function f:Paint(w, h)
			surface.SetDrawColor(40, 40, 40)
			surface.DrawRect(0, 0, w, h)


			surface.SetDrawColor(30, 30, 30)
			self:DrawGradientBorder(w, h, 4, 4)

			draw.SimpleText(name, "OSB24", 64 + (w - 64) / 2, 4, color_white, 1, 5)

			draw.SimpleText("Generates: " .. gens, "TWB24", 80, h/2 + 12, green, 0, 1)

			draw.SimpleText("Stored: " .. v:GetPower() .. "PW", "TWB24", w/2 + 56, h/2 + 12, blue, 0, 1)
			
		end

		local gen = vgui.Create("ModelImage", f)
		gen:Dock(LEFT)
		gen:DockMargin(8, 8, 8, 8)
		gen:SetSize(48, 48)

		gen:SetModel(v:GetModel())

		local disc = vgui.Create("FButton", f)
		disc:Dock(RIGHT)
		disc:SetSize(24, 56)
		disc:DockMargin(8, 4, 4, 4)

		function disc:PostPaint(w, h)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawMaterial("https://i.imgur.com/6nOrAAO.png", "disconnecttall.png", 4, 0, w-8, h)
		end

		function disc:OnHover()
			popup = true 
			curtip = "Disconnect " .. name
			hovd = self
		end

		function disc:OnUnhover()
			if hovd == self then 
				popup = false 
				hovd = nil
			end
		end
	end

	return scr
end

local red = Color(200, 100, 100)

function ENT:CreateConsumersScroll(pnl, me)
	local scr = self:CreateBaseScroll(pnl, "Consumers", {
		url = "https://i.imgur.com/poRxTau.png", 
		name = "electricity.png"
	})

	scr.X = 450
	scr.Y = pnl.CircleY

	for k,v in ValidPairs(me.Electronics) do 
		local f = scr:Add("InvisPanel")
		f:Dock(TOP)
		f:DockMargin(0, 0, 0, 8)
		f:SetTall(64)

		local name = v.PrintName or "wtf"
		local gens = "-" .. (v.PowerRequired or -1337) .. "PW"

		function f:Paint(w, h)
			surface.SetDrawColor(40, 40, 40)
			surface.DrawRect(0, 0, w, h)


			surface.SetDrawColor(30, 30, 30)
			self:DrawGradientBorder(w, h, 4, 4)

			draw.SimpleText(name, "OSB24", 64 + (w - 64) / 2, 4, color_white, 1, 5)

			draw.SimpleText("Consumes: " .. gens, "TWB24", 80, h/2 + 12, red, 0, 1)

			draw.SimpleText("Stored: " .. v:GetPower() .. "PW", "TWB24", w/2 + 64, h/2 + 12, blue, 0, 1)
			
		end

		local ent = vgui.Create("ModelImage", f)
		ent:Dock(LEFT)
		ent:DockMargin(8, 8, 8, 8)
		ent:SetSize(48, 48)

		ent:SetModel(v:GetModel())

		local disc = vgui.Create("FButton", f)
		disc:Dock(RIGHT)
		disc:SetSize(24, 56)
		disc:DockMargin(8, 4, 4, 4)

		function disc:PostPaint(w, h)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawMaterial("https://i.imgur.com/6nOrAAO.png", "disconnecttall.png", 4, 0, w-8, h)
		end

		function disc:OnHover()
			popup = true 
			curtip = "Disconnect " .. name
			hovd = self
		end

		function disc:OnUnhover()
			if hovd == self then 
				popup = false 
				hovd = nil
			end
		end
	end

	return scr
end

function ENT:QMOnClose(qm, self, pnl)
	print("called on close")
	if pnl.Cloud then pnl.Cloud:Remove() pnl.NoCloud = true end
end

function ENT:QMThink(qm, self, pnl)

	if pnl.NoCloud then print("okay????????") return end --just in case

	pnl.Cloud = pnl.Cloud or vgui.Create("Cloud")

	local cloud = pnl.Cloud

	cloud.MaxW = 512 
	cloud.Middle = 0.5
	cloud.Font = "OSB36"
	cloud:Popup(popup)
	cloud:SetLabel(curtip)
	cloud:SetAbsPos(pnl:LocalToScreen(425, 130))
end

function ENT:OpenShit(qm, self, pnl)

	pnl:SetSize(850, 700)	--cant fit
	pnl:CenterHorizontal()

	local x, y = 425, 200	--ScreenToLocal doesn't work for some reason...

	local me = BWEnts[self]

	pnl.CircleX = x

	local gens = self:CreateGeneratorsScroll(pnl, me)

	qm:AddPopIn(gens, gens.X, gens.Y + pnl.CircleSize, 0, 32)

	local consumers = self:CreateConsumersScroll(pnl, me)

	qm:AddPopIn(consumers, consumers.X, consumers.Y + pnl.CircleSize, 0, 32)

end


function ENT:CLInit()
	print("called")
	
	--[[poles[#poles + 1] = self
	local me = BWEnts[self]
	me.Generators = {}

	me.Electronics = {}
	me.Grid = {}

	me.ThrowLightning = {}]]

	local qm = self:SetQuickInteractable()
	qm.OnOpen = function(...) self:OpenShit(...) end
	qm.Think = function(...) self:QMThink(...) end
	qm.OnFullClose = function(...) self:QMOnClose(...) end
end

local cab = Material("cable/cable2")
local lightning = Material("trails/electric")

hook.Add("PostDrawTranslucentRenderables", "DrawPoleCables", function(d, sb)
	--local b = bench("rendering")
	--b:Open()

	if sb or #poles <= 0 then return end 

	

	for k, pole in pairs(poles) do 

		if not IsValid(pole) then table.remove(poles, k) continue end

		local me = BWEnts[pole]
		local pos = pole:LocalToWorld(pole.ConnectPoint)
		local newpos = me.LastCablePos ~= pos 

		me.LastCablePos = pos

		if not me.Generators or not me.ThrowLightning then continue end 

		render.SetMaterial(cab)

		for id, gen in pairs(me.Generators) do
			--print("drawing", gen)
			if not IsValid(gen) then me.Generators[gen] = nil continue end

			local genpos = gen:GetPos()

			local them = BWEnts[gen]

			if newpos or them.LastCablePos ~= genpos or them.LastCableTo ~= pos or not them.Cable then 
				them.Cable = GenerateCable(pos, genpos, 3, 10, true)
				them.LastCablePos = genpos
				them.LastCableTo = pos
			end

			local cable = them.Cable


			render.StartBeam(#cable)

				for k, v in ipairs(cable) do
					render.AddBeam( v, 2, 0.5, color_white)
				end

			render.EndBeam()
		end

		--b:Close()

		--print(b)

		render.SetMaterial(lightning)

		for ent, t in pairs(me.ThrowLightning) do 
			local time = math.min(0.2, t.dist)
	
			local frac = (CurTime() - t.t) / time

			if frac >= 1 then me.ThrowLightning[ent] = nil return end
			--len is .1 of frac
			local s = LerpVector(frac, t.start, t["end"])

			local edir = (t["end"] - t.start)
			edir:Normalize()

			local dist = math.min(t.dist, 128, s:Distance(t["end"]))
			edir = edir * dist

			render.DrawBeam(s, s + edir, 7, frac*5, frac*5 + dist/t.dist)	--multiplying frac gives it a flow-animation where the texture flows back <-- front

		end
	end

	--b:Close()
end)