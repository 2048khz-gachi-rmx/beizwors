AddCSLuaFile()

ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "AI Base Wall"
ENT.Spawnable = true
ENT.IsAIWall = true

function ENT:Initialize()

end


local colT = {}

function ENT:TestCollision( startpos, delta, isbox, extents )
	if not self.PhysCollide or not self.PhysCollide:IsValid() then
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

	colT.HitPos = hit
	colT.Normal = norm
	colT.Fraction = frac

	return colT
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
	end
end

local matCache = {}
ENT.Material = "brick/brick_model"

function ENT:Draw()
	local min, max = self:GetCollisionBounds()
	self:SetRenderBounds(min, max)

	local mat = self:GetMaterial()
	if mat == "" then mat = self.Material end

	if not self.PhysCollide then
		self:InitPhys(min, max)
	end

	if mat and mat ~= "" then
		self:DrawModel()
	else
		render.DrawWireframeBox(self:GetPos(), self:GetAngles(), min, max, Colors.Purpleish, true)
	end
end

local t = {}

function ENT:GetRenderMesh()
	if not self.Mesh then self:CreateMesh() end

	local mat = self:GetMaterial()
	if mat == "" then mat = self.Material end

	if mat and mat ~= "" then
		local imat = matCache[mat] or Material(mat, "vertexlitgeneric")
		matCache[mat] = imat
	end

	t.Mesh = self.Mesh
	t.Material = matCache[mat]
	return t
end

function ENT:CreateMesh()
	self.Mesh = Mesh()

	local min, max = self:GetCollisionBounds()

	local x0 = max.x
	local y0 = max.y
	local z0 = max.z

	local x1 = min.x
	local y1 = min.y
	local z1 = min.z

	local positions = {
		Vector( x0, y0, z0 ),
		Vector( x0, y0, z1 ),
		Vector( x0, y1, z0 ),
		Vector( x0, y1, z1 ),
		Vector( x1, y0, z0 ),
		Vector( x1, y0, z1 ),
		Vector( x1, y1, z0 ),
		Vector( x1, y1, z1 )
	}

	local normals = {
	   Vector( -1,  0,  0 ),
	   Vector(  1,  0,  0 ),
	   Vector(  0, -1,  0 ),
	   Vector(  0,  1,  0 ),
	   Vector(  0,  0, -1 ),
	   Vector(  0,  0,  1 ),
	}

	local indices = {
		1, 7, 5,
		1, 3, 7,
		6, 4, 2,
		6, 8, 4,
		1, 6, 2,
		1, 5, 6,
		3, 8, 7,
		3, 4, 8,
		1, 4, 3,
		1, 2, 4,
		5, 8, 6,
		5, 7, 8,
	}

	normals = table.Reverse(normals)

	local tangents = {
		{ 0, 1, 0, -1 },
		{ 0, 1, 0, -1 },
		{ 0, 0, 1, -1 },
		{ 1, 0, 0, -1 },
		{ 1, 0, 0, -1 },
		{ 0, 1, 0, -1 },
	}

	local uCoords = {
	   0, 1, 0,
	   0, 1, 1,
	   0, 1, 0,
	   0, 1, 1,
	   0, 1, 0,
	   0, 1, 1,
	   0, 1, 0,
	   0, 1, 1,
	   0, 1, 0,
	   0, 1, 1,
	   0, 1, 0,
	   0, 1, 1,
	}

	local vCoords = {
	   0, 1, 1,
	   0, 0, 1,
	   0, 1, 1,
	   0, 0, 1,
	   0, 1, 1,
	   0, 0, 1,
	   0, 1, 1,
	   0, 0, 1,
	   0, 1, 1,
	   0, 0, 1,
	   0, 1, 1,
	   0, 0, 1,
	}

	local map = 128
	local verts = {}

	--[=[
	for vert_i = 1, #indices do
		local face_i = math.ceil( vert_i / 6 )

		verts[vert_i] = {
			pos = positions[indices[vert_i]],
			normal = normals[face_i],
			u = uCoords[vert_i],
            v = vCoords[vert_i],
			userdata = tangents[face_i]
		}
	end
	]=]

	for fi = 0, 5 do
		for i=fi * 6 + 1, fi * 6 + 6 do
			local c1 = positions[indices[fi * 6 + 1]]
			local c2 = positions[indices[i]] --positions[indices[fi  * 6 + 6]]
			local diff = (c2 - c1)
			diff:Rotate(normals[fi + 1]:Angle())

			local u, v = diff[2] / map, diff[3] / map

			verts[i] = {
				pos = positions[indices[i]],
				normal = normals[fi + 1],
				u = u,
	            v = v,
				userdata = tangents[fi + 1]
			}

		end
	end

	self.Mesh:BuildFromTriangles( verts )
end