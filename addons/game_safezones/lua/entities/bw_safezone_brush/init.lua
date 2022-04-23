ENT.Base = "base_brush"
ENT.Type = "brush"

-- include("logic.lua")

Safezones = Safezones or {}
Safezones.Brushes = Safezones.Brushes or {}
Safezones.Points = Safezones.Points or {}

local points = Safezones.Points

function ENT:Initialize()
	self:SetSolid(SOLID_BBOX)
	Safezones.Brushes[#Safezones.Brushes + 1] = self

	local d = ents.Create("bw_safezone_dummy")
	d.ZoneName = self.ZoneName
	d:Spawn()

	self.Dummy = d

end

function ENT:SetBrushBounds(p1, p2)
	if not isvector(p1) or not isvector(p2) then error('Trying to set an invalid brush vector!') return end
	self:SetCollisionBoundsWS(p1, p2)
	self.P1 = p1
	self.P2 = p2
	local mid = (p1 + p2) / 2
	local d = self.Dummy
	if not IsValid(d) then return end

	d:SetPos(mid)
	d.P1 = p1
	d.P2 = p2
end

function ENT:StartTouch(ent)
	if not IsValid(ent) then return end
	Safezones.StartTouch(self, ent)
end


function ENT:EndTouch(ent)
	Safezones.EndTouch(self, ent)
end

function ENT:Touch(ent)
	Safezones.Touch(self, ent)
end

function Safezones.Reload()

	for k,v in pairs(Safezones.Brushes) do

		if IsValid(v) then
			if IsValid(v.Dummy) then
				v.Dummy:Remove()
			end

			v:Remove()
			Safezones.Brushes[k] = nil
		end

	end

	for k,v in pairs(points) do
		local me = ents.Create("bw_safezone_brush")
		me.ZoneName = k
		me:Spawn()

		me:SetBrushBounds(v[1], v[2])
	end
end

hook.Add("InitPostEntity", "SafezonesSpawn", Safezones.Reload)
hook.Add("OnReloaded", "SafezonesSpawn", Safezones.Reload)
hook.Add("PostCleanupMap", "Safezones", Safezones.Reload)