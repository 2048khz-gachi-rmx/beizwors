include("shared.lua")
AddCSLuaFile("shared.lua")

local thxSource

function ENT:CLInit()

end

ENT.DrawInitialized = false
function ENT:DrawInit()
	if self.DrawInitialized then return end

	self.powerTri = TriWave:new()
		:SetSpeeds(-1 / 1.8, 1 / 1.8)

	self.switchTri = TriWave:new()
		:SetSpeeds(-1 / 0.2, 1 / 0.2)

	self.DrawInitialized = true
	self._lightChange = CurTime()
end

local log = math.log
local l2 = log(2)
-- man
local inRev = function(x) return x == 0 and 0 or 1 + log(x) / 10 / l2 end
local outRev = function(x) return x == 1 and 1 or -log(1 - x) / 10 / l2 end
local ez = math.ease

function ENT:DoPowerArrow()
	local tri = self.powerTri
	local dir = tri:GetDirection()
	local fn = dir and ez.OutExpo or ez.InExpo

	local fr = fn(tri:Get())

	self:SetPoseParameter("power", fr * 100)
	self:SetPoseParameter("switch", math.ease.InOutCirc(self.switchTri:Get()) * 100)
end

function ENT:LightsChanged(_, old, new)
	self:DrawInit()

	self.switchTri:SetDirection(new)

	self:Timer("switchanim", 0.07, 1, function()
		self.powerTri:SetDirection(new)
		local ofn = old and ez.OutExpo or ez.InExpo
		local pre = ofn(self.powerTri:Get())

		local nt = new and outRev(pre) or inRev(pre)
		self.powerTri:Set(nt)
	end)
end

function ENT:Draw()
	if halo.RenderedEntity() ~= self then
		self:DrawInit()

		local therFr = math.ease.InOutSine(self:GetFrac()) * 100
		self:SetPoseParameter("thermometer", therFr)
		self:DoPowerArrow()

		self:InvalidateBoneCache()
	end

	self:DrawModel()
end


local tex = GetRenderTargetEx( "cocfallRT", 512, 256, RT_SIZE_OFFSCREEN,
		 MATERIAL_RT_DEPTH_SHARED, 0, 0, IMAGE_FORMAT_RGBA8888 )

local rtMat = CreateMaterial("cocfallRTMat", "UnlitGeneric", {
	["$basetexture"] = tex:GetName(),
	["$translucent"] = "1"
})



-- nice name
local cocaine = CreateMaterial("cocaineReglir1rMat", "UnlitGeneric", {
	["$basetexture"] 			= "models/craphead_scripts/the_cocaine_factory/utility/pot_soda",
	["$detail"] 				= "detail/dt_smooth1.vtf",
	["$detailscale"] 			= "1",
	["$detailblendmode"] 		= "8",
})

local mask2 = Material( "gui/gradient_up" )

local function doRTMask(fr, w, h)
	local gradH = 192
	local midY = Lerp(fr, h, -gradH)

	render.SetWriteDepthToDestAlpha( false )
		render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_MIN )
			surface.SetMaterial( mask2 )
			surface.DrawTexturedRect(0, midY, 512, gradH)
			surface.SetDrawColor(0, 0, 0, 3)
			surface.DrawRect(0, midY - h, 512, h)
		render.OverrideBlend( false )
	render.SetWriteDepthToDestAlpha( true )
end

--[[hook.Add( "HUDPaint", "DrawExampleMaskMat", function()
	render.PushRenderTarget( tex )
	cam.Start2D()
		render.Clear( 0, 0, 0, 0 )
		RenderMaskedRT()
	cam.End2D()
	render.PopRenderTarget()

	-- This is just for debugging, to see what it looks like without the mask
	-- RenderMaskedRT()

	-- Actually draw the Render Target to see the final result.
	surface.SetDrawColor( color_white )
	surface.SetMaterial( myMat )
	surface.DrawTexturedRect( 520, 0, TEX_SIZE, TEX_SIZE )
end )]]

function ENT:DoDryMenu(open, nav, inv)
	local canv, new = nav:ShowAutoCanvas("grow", nil, 0.1, 0.2)
	nav:PositionPanel(canv)

	if not new then
		return
	end

	local iPnl = vgui.Create("InventoryPanel", canv)
	iPnl.NoPaint = true
	iPnl:EnableName(false)
	iPnl:SetShouldPaint(false)
	iPnl:SetInventory(self.Buf)
	iPnl:SetSize(canv:GetWide() * 0.9, canv:GetTall() * 0.35)
	iPnl:SetPos(0, canv:GetTall() - iPnl:GetTall())
	iPnl:CenterHorizontal()

	local slot = vgui.Create("ItemFrame", iPnl)
	slot:Dock(FILL)

	iPnl:TrackItemSlot(slot, 1)
	slot:BindInventory(self.Buf, 1)

	slot.amt = slot:GetItem() and slot:GetItem():GetAmount() or 0

	if slot.ModelPanel then
		slot.ModelPanel:Hide()
	end
	local ent = self

	slot:On("InventoryUpdated", "HideModel", function()
		local amt = slot:GetItem() and slot:GetItem():GetAmount() or 0
		local t = amt < slot.amt and 0.3 or 1.8

		slot:To("amt", amt, t, 0, 0.5)

		slot.amtfr = 1
		slot:RemoveLerp("amtfr")
		slot:To("amtfr", 0, t, 0.2, 1)
		
		if slot.ModelPanel then
			slot.ModelPanel:Hide()
		end
	end)

	local progCol = Color(230, 230, 200)

	slot:On("PostDrawBorder", "DrawProc", function(_, w, h, col)
		local fr = ent:GetFrac()
		draw.RoundedBox(slot.Rounding, 0, 0, w * fr, h, progCol)
	end)

	local fall = thxSource()
	local colUnpr, colPr = Color(250, 250, 200), Color(255, 255, 255)
	local tcol = Color(0, 0, 0)
	local why_source = Vector()

	function slot:PostPaint(w, h)
		local itm = self:GetItem()
		--if not itm then return end

		local amt = self.amt
		local amtTo = self:GetTo("amt") and self:GetTo("amt").ToVal or amt

		if amtTo > amt then
			local fallA = self.amtfr
			do
				render.PushRenderTarget( tex )
				cam.Start2D()
					render.Clear( 0, 0, 0, 0, true, true )

					local nH = (h - 4) * fallA
					local nY = Lerp(fallA, h - 4, 2)
					surface.SetDrawColor(tcol)
					surface.SetMaterial(fall)
					local t = 128
					surface.DrawTexturedRectUV(2, 2, w, h, 0, 0, w / t, h / t)
					t = 160
					surface.DrawTexturedRectUV(2, 2, w, h, 0, 0, w / t, h / t)
					t = 64
					surface.DrawTexturedRectUV(2, 2, w, h, 0, 0, w / t, h / t)
					surface.DrawTexturedRectUV(2, 2, w, h, 0, -.2, w / t - 0.2, h / t)
					doRTMask(fallA, w, h)
				cam.End2D()
				render.PopRenderTarget()
			end

			surface.SetDrawColor(255, 255, 255)
			surface.SetMaterial( rtMat )
			surface.DrawTexturedRectUV( 0, 0, w, h, 0, 0, w / 512, h / 256 )
		end

		local amtFr = amt / Inventory.Util.GetBase("cocaine"):GetMaxStack()

		tcol:Lerp(ent:GetFrac(), colUnpr, colPr)
		why_source:SetUnpacked(tcol.r / 255, tcol.g / 255, tcol.b / 255)

		cocaine:SetVector("$color", why_source)

		surface.SetMaterial(cocaine)
		surface.SetDrawColor(tcol)
		local sH = amtFr * h * 0.6
		local y = h - sH
		surface.DrawTexturedRectUV(2, h - sH, w - 4, sH, 0, (y / 128), 3, h / 128)
	end

	local switch = vgui.Create("FButton", canv)
	switch:SetSize(36, 36)
	switch:SetPos(iPnl.X + iPnl:GetWide() - switch:GetWide() - 4,
		iPnl.Y - 4 - switch:GetTall())

	switch:SetIcon(
		Icon("https://i.imgur.com/YNRPO5z.png", "powerbtn.png")
			:SetSize(26, 26)
	)


	local dt = DeltaText()
		:SetFont("EX24")

	dt.AlignX = 2
	dt.AlignY = -1.125

	local doit = dt:AddText("")
	local id, frag = doit:AddFragment(ent:GetLightsOn() and "Stop" or "Start")
	doit:AddFragment(" Drying")

	dt:ActivateElement(doit)

	function switch:DoClick()
		net.Start("cocdrier")
			net.WriteEntity(ent)
			net.WriteBool(not ent:GetLightsOn())
		net.SendToServer()
	end

	local lightCol = Color(220, 240, 250)
	local lmat = Material("models/craphead_scripts/the_cocaine_factory/drying_rack/vol")

	nav.a = ent:GetLightsOn() and 1 or 0

	function canv:PostPaint(w, h)
		local li = ent:GetLightsOn()
		doit:ReplaceText(id, li and "Stop" or "Start")
		dt:Paint(switch.X - 8, switch.Y + switch:GetTall() / 2)

		nav:LerpColor(nav.HeaderColor, li and lightCol or Colors.Header, 0.2, 0, 0.3)
		nav:To("a", li and 1 or 0, 0.7, 0, 1)

		switch:SetColor(not li and Colors.Sky or Colors.Button)
	end

	function nav:PostPaint(w, h)
		surface.SetMaterial(lmat)
		surface.SetDrawColor(255, 255, 255)

		if self.a > 0 then
			local amt = 3
			for i=0, amt do
				local ch = math.RemapClamp(self.a, 0, 1 / amt * i, 0, 1)
				if math.random() > ch then continue end

				surface.DrawTexturedRect(i * (w + (-w / 3 + w / amt)) / amt,
					self.HeaderSize,
					w / 3, h * 2)
			end
		end
	end
end

function ENT:Used()
	local scale, scaleW = Scaler(1600, 900, true)
	local menu = vgui.Create("FFrame")

	local inv = Inventory.Panels.CreateInventory(
		Inventory.GetTemporaryInventory(LocalPlayer()),
		nil, {
			SlotSize = scaleW(64)
		}
	)

	inv:ShrinkToFit()

	local h = math.max(inv:GetTall(), scale(352))

	inv:SetTall(h)
	menu:SetSize(scaleW(500), h)
	menu:PopIn()

	menu:Bond(inv)
	inv:Bond(menu)
	menu:Bond(self)

	local poses, tW = vgui.Position(8, menu, inv)
	inv:CenterVertical()

	for k,v in pairs(poses) do
		k:SetPos(ScrW() / 2 - tW / 2 + v, inv.Y)
	end

	inv:MakePopup()

	self:DoDryMenu(true, menu, inv)
end

net.Receive("cocdrier", function()
	local e = net.ReadEntity()
	e:Used()
end)

local funnyVMT = [[
"UnlitGeneric"
{
    "$basetexture" "models/craphead_scripts/the_cocaine_factory/extractor/pixels"
    "$vertexcolor" 1
    "$vertexalpha" 1
    "$nocull" 1

    "$angle" 180
    "$translate" "[0 0]"
    "$center" "[.5 .5]"
    "$scale" "[1 1]"
    "$num" ".1"
    "$num2" "0"

    "Proxies"
    {
        "LinearRamp"
        {
            "rate" 0.8
            "initialValue" 0
            "resultVar" "$num2"
        }

        "LinearRamp"
        {
            "rate" .03
            "initialValue" 0
            "resultVar" "$translate[0]"
        }

        "Add"
        {
        srcVar1 $num
        srcVar2 $num2
        resultvar "$translate[1]"
        }

        "TextureTransform"
        {
            "translateVar" "$translate"
            "rotateVar" "$angle"
            "centerVar" "$center"
            "scaleVar"     "$scale"
            "resultVar" "$basetexturetransform"
        }
    }
}]]

local sha = util.SHA1(funnyVMT)
local yea

function thxSource()
	if yea then return yea end

	if file.Exists("hdl/thx_source.vmt", "DATA") then
		local dat = file.Read("hdl/thx_source.vmt", "DATA")

		if util.SHA1(dat) == sha and #dat == #funnyVMT then
			-- has to be ../ SPECIFICALLY for vmts
			-- pngs work fine; thx gmod
			yea = Material("../data/hdl/thx_source.vmt")
			return yea
		end
	end

	-- whats that you want proxies in CreateMaterial? more like go fuck yourself
	file.Write("hdl/thx_source.vmt", funnyVMT)

	yea = Material("../data/hdl/thx_source")
	return yea
end