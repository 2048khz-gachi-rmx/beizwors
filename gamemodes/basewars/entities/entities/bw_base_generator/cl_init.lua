ENT.Base = "bw_base"
ENT.Type = "anim"
ENT.PrintName = "Base Generator"

AddCSLuaFile("shared.lua") --???
include("shared.lua")

function ENT:OpenShit(qm, self, pnl)
	if not IsValid(pnl) then error("WTF " .. tostring(pnl)) return end

	local ent = self
	self.IsQMInteracting = true

	if ent.GenerateOptions then

		if qm.Panels then

			local valid = #qm.Panels > 0

			for k, p in ipairs(qm.Panels) do
				if not IsValid(p) then valid = false break end
			end

			if valid then goto skipOptions end 	-- every option is valid; don't recreate and bail
												-- had ta use a goto here
		end

		local pnls = {ent:GenerateOptions(qm, pnl)}

		qm.Panels = pnls
	end

	::skipOptions::

end

function ENT:CloseAll(qm, self, pnl)
	self.IsQMInteracting = false
	if not IsValid(pnl) then return end

	if qm.Panels then
		for k,v in pairs(qm.Panels) do
			v:PopOut()
			qm.Panels[k] = nil
		end
	end
end

function ENT:PaintStructureInfo(w, y)
	local txt = ("+%d"):format(self.PowerGenerated)
	local tx2 = "pw/s"
	if self.PowerGenerated == 0 then return 0 end

	local ic = Icons.Electricity
	local icSz = 24
	local icPad = 4

	local smallFont = "OSB18"
	local tw2, th2 = surface.GetTextSizeQuick(tx2, smallFont)
	local tw, th = surface.GetTextSizeQuick(txt, "OSB24")

	local totalW = tw + icSz + icPad + tw2

	ic:Paint(w / 2 - totalW / 2, y, icSz, icSz)

	surface.SetTextColor(Colors.Money)
	draw.SimpleText2(txt, nil,
		w/2 - totalW / 2 + icSz, y, nil, 0, 5)

	surface.SetFont(smallFont)
	surface.SetTextPos(w/2 - totalW/2 + icSz + tw, y + th * 0.875 - th2 * 0.875)
	surface.DrawText(tx2)

	return math.max(icSz, draw.GetFontHeight(smallFont)) + 4
end

function ENT:CLInit()
	local qm = self:SetQuickInteractable()
	local base = self.BaseClass
	qm.OnOpen = function(...) self:OpenShit(...) end
	qm.OnFullClose = function(...) base.CloseAll(self, ...) end
	--qm.OnReopen = OpenShit

	--self:OnChangeGridID(self:GetGridID())
end


function ENT:Think()
	-- what the actual fuck is this
end
