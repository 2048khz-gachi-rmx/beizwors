AddCSLuaFile()

ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "AI Base Wall"
ENT.Spawnable = true

function ENT:Initialize()

end


function ENT:TestCollision( startpos, delta, isbox, extents )
	if not IsValid( self.PhysCollide ) then
		return
	end

	local max = extents
	local min = -extents
	max.z = max.z - min.z
	min.z = 0

	local hit, norm, frac = self.PhysCollide:TraceBox( self:GetPos(), self:GetAngles(), startpos, startpos + delta, min, max )

	if not hit then
		return
	end

	return {
		HitPos = hit,
		Normal  = norm,
		Fraction = frac,
	}
end

function ENT:InitPhys(min, max)
	self.PhysCollide = CreatePhysCollideBox(min, max)
	self:SetCollisionBounds(min, max)

	if SERVER then
		self:PhysicsInitBox(min, max)
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysWake()
	end

	if CLIENT then
		self:SetRenderBounds(min, max)
	end

	self:EnableCustomCollisions(true)
	self:DrawShadow(false)
	local po = self:GetPhysicsObject()
	if po:IsValid() then
		po:EnableMotion(false)
		print("disabling motion")
	else
		print("invalid physobj?")
	end
end

function ENT:Draw()
	local min, max = self:GetCollisionBounds()
	if not self.PhysCollide then
		self:InitPhys(min, max)
	end

	render.DrawWireframeBox(self:GetPos(), self:GetAngles(), min, max, color_white, true)
end
