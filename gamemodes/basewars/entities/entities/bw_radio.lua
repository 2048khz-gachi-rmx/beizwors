AddCSLuaFile()

ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "Radio"

ENT.Model = "models/props/cs_office/radio.mdl"
ENT.IsRadio = true

if SERVER then
	function ENT:Initialize()


		self:SetModel(self.Model)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMaxHealth(0)
	    local phys = self:GetPhysicsObject()

		if (phys:IsValid()) then
			phys:Wake()
		end

	end

	function ENT:OnTakeDamage(dmg)
		dmg:SetDamage(0)
		dmg:ScaleDamage(0)
	end

	hook.Add("EntityTakeDamage", "don't hurt me :(", function(ent, dmg)
		if ent.IsRadio then dmg:SetDamage(0) return true end
	end)

else

	function ENT:Initialize()
		local qm = self:SetQuickInteractable()
		qm.OnOpen = function(self, ent, pnl)
			local p = pnl:Add("FFrame")
			p:SetSize(400, 100)
			p:SetDraggable(false)

			p:Center()

			p:SetCloseable(false, true)

			p.Y = p.Y + pnl.CircleSize + 16

			p.Shadow = {}

			local sl = p:Add("FNumSlider")
			sl:SetSize(350, 50)
			sl:Center()

			sl.Y = (p:GetTall() - p.HeaderSize) / 2

			sl:SetText("Volume")
			sl:SetMin(0)
			sl:SetMax(1)
			sl:SetDecimals(2)
			sl:SetValue(PZVolume)

			sl.Label:SetFont("EXM24")

			sl.OnValueChanged = function(self, val)
				cookie.Set("HotelRadioVolume", val)	-- cookie lib takes care of ratelimiting for me
				PZVolume = val
			end

			qm:AddPopIn(p, p.X, p.Y, 0, 48)
		end
	end
end
