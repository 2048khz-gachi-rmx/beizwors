include("shared.lua")
AddCSLuaFile("shared.lua")

local sideData = [[XQAAAQDQPAAAAAAAAAA7GUqsC9K+WGkjv/Folr5c+X9PU9Rd2+ze/wBbmepZKCRipvEkaPbd
IebKHVDDRCWhMMKfrfx7NEXD0+iYAKCIeGPTJ4ly2/EAsdARCTLxQM56kfs6x6r5cvPiOHyr
ti4dh1BlBm9uSKKYhdH4E+03gnPLPkD//M2dmVS69tqKExpaCmiylWrhP3VCzqYujll0Dd0x
SItG/ndHofVeOp54uP2nNVJrHWpSUuXIHExM1mAi7Ke/vwLGFJpvRBhH1asT66vy2lXeuan8
8JBgSb9/1f/ulVYzgpcSBgnBvBvjWzkWlQgX7Cc81r9kHxiXcEOEcgOyW18K1xaLXw6Du+uj
jucdrDoDfAN85K9MuHAEe2z3c4Gv+JCDkNdyO8e1Q7fmexegabXqnG1+34SxkQALSlaJlAoq
BZ9DD+k+zcikrBGMlX6Rr0ZVu38++sn/+Juvy/sRHCBR+XzQh5G6L3Nh6fa7k+i/vdWRWH0l
PYyJeHRRzvhkc3tc7gqDWuOyvfR6VTOEeN0JhY2/WDXVRzYp27vWVY9VCeHTDgQ7Vkk9PxDc
zyHplWBjHHrGopakb5i4ih3cEZ+0gCqgxAMM4dzC+MScA9FApWJr51AP+5ngipKUIkf7wF5e
jEK7PqjzEY1BiUVNDXjRmS+TsiNQo34D41ed+mNfDcrevGgWik6e9xR6ryd19saxg9gXm89h
cjOL2g+C9UBgYOY4e/ZjZvKYfke4cT7+FUIq9/egITB8/AQkvbJvnXTngzFJXTczJs6KoWvm
LCOx+S2rJ9jfKsBCicdYH+Gqz0SS0aMqtRry8nMOyB4LqcVkRlWuabWOWZKkM5axvzw7J6EF
VIHe8V/fWKle238ZRrDUP9Ezfb5AJ+WUjlqcm6pWVfp4zRZXJho208GeFVUHX8h9JQq3b0aT
CjFgdijLU6yMyYzJZUOK35TtzV+/arM0+DD+AJRkl7bFZIAlHUGyeab3yoT02XcI++6k0YdE
LcpOmGKKRCXlBrhIunVV+Ds6S/Ndu6burqnUkzEKqdxC9K2zxiiRkDD+JCnfaQxh2JGTejYu
DjutZuCkYjFbpawRUKNkDmWsviZycox6j5yoxZc4DJ6OakAH2bSSLRbPk3KRA2GsqKMZS0Qo
PFRm42NxMryGjne055Zly3ff4sSVtFPtww2QzXAZGfJ9TofWdsb/oALQD1hqM9PbBHYn]]
sideData = util.Decompress(util.Base64Decode(sideData))

local doorData = [[XQAAAQCBDAAAAAAAAAA7GUqsC9K+WGkjv/Folr5c+X9PU9Rd2+ze/wBbmepZKCRipvEkaPbd
IebKHVDDRCWhMMKfrfx7NEXD0+iYAKCIeGPTJ/tXavZaQ1wLSFo9h0PKUvQGYdSjTyWT4axM
auoupt+ZD2a0l29HD8c5oAJPouYOOeRNI5FTlLsgBDvwbKNbUb2YtBu9k8cAyIUS9EY1J0qV
DuwiZmnLsSUxhjWWqhMefFaveAWwbPG+jsUbeAbLilSn6gwO0jg4vD+zN9ZVs7G/HY2HOSUl
GRLq+Vrh2vhW9YhugasFTRy5nsp6NCQCmCekA+GQzUu+PdeBIqYe6qgxXdxU4+PBvDLPYpdR
kp27cFFPpTmDvk4R2VqksJ+MYETotuu3rGfHdGj+qKQbM7roQEvV6huqJ85D1KXaAIZiRITS
eV0k6Gemj9VB5OjGPDXmdz+hCw9impVoLxJoWPfOnoRm2v4oK36yyW2Ld/CLydRMgWjxmmIz
0Paeb07U]]

doorData = util.Decompress(util.Base64Decode(doorData))

local anim

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:CLInit()
	anim = anim or Animatable("MorphDoors")

	local dist = self.Dists
	self:SetRenderBounds(Vector(-self.BoxThickness, -dist[1], -dist[2]), Vector(self.BoxThickness, dist[1], dist[2]), Vector(4, 4, 4))

	self.LeftClose = 0
	self.RightClose = 0
end

function ENT:OnOpen()
	anim = anim or Animatable("MorphDoors")

	anim:MemberLerp(self, "LeftClose", 0, 0.3, 0, 0.3)
	anim:MemberLerp(self, "RightClose", 0, 0.3, 0, 0.3)
end

function ENT:OnClose()
	anim = anim or Animatable("MorphDoors")

	anim:MemberLerp(self, "LeftClose", 1, 0.3, 0, 0.3)
	anim:MemberLerp(self, "RightClose", 1, 0.3, 0, 0.3)
end

local cols = {
	[true] = Colors.Green:Copy(),
	[false] = Colors.Red:Copy()
}

for k,v in pairs(cols) do
	v.a = 50
end

function ENT:GenerateMesh(vectbl)

	self.DoorMeshes = {
		Mesh(),
		Mesh(),
		Mesh()
	}

	local mshes = self.DoorMeshes

	local tris = smdparse(sideData, true)
	if not tris then error("Fuck") return end

	self.SMD = tris

	local bounds, dists = self:GetBounds()

	local l = {}
	local r = {}

	for name, triangles in pairs(tris) do
		local t = {}
		l[name] = t

		local t2 = {}
		r[name] = t2

		for k,v in ipairs(triangles) do
			local v1, v2 = Vector(), Vector()
			v1:Set(v.pos)
			v2:Set(v.pos)

			local n1, n2 = Vector(), Vector()
			n1:Set(v.normal)
			n2:Set(v.normal)

			t[k] = {
				pos = v1,
				normal = n1,
				u = v.u,
				v = v.v,
			}

			t2[k] = {
				pos = v2,
				normal = n2,
				u = v.u,
				v = v.v,
			}

		end
	end


	for k,v in pairs(r) do
		if k == "door_bottom" then

		elseif k == "door_top" then

		else
			local msh = mshes[3]
			local ang = Angle(0, -90, 0)
			local vec = Vector()


			for _, tri in ipairs(v) do
				local vec2 = Vector()
				vec2:Set(tri.pos)
				tri.pos = vec2
			end

			msh:BuildFromTriangles(v)
		end
	end

	local dtris = smdparse(doorData, true)
	if not dtris then error("What") return end

	for k,v in pairs(dtris) do
		local msh = mshes[2]

		for _, tri in ipairs(v) do
			local vec2 = Vector()
			vec2:Set(tri.pos)
			tri.pos = vec2
		end

		msh:BuildFromTriangles(v)
	end
end

local mat = Material( "models/debug/debugwhite" )
local wf = Material( "models/wireframe" )

local mtrx = Matrix()
local shang = Angle()
local scl = Vector(1, 1, 1)
local magicOffset = Vector(0, 6.66, 0)
local vReuse = {}

function ENT:Draw()
	self:DrawModel()

	local pos = self:GetPos()
	local ang = self:GetAngles()

	if not self.DoorMeshes then
		local verts, vertDist, all_hit = self:GetBounds()

		local mins = Vector(-self.BoxThickness, -vertDist[2], vertDist[4])
		local maxs = Vector(self.BoxThickness, vertDist[1], -vertDist[3])
		OrderVectors(mins, maxs)

		render.SetColorMaterial()
		render.DrawQuad(verts[1], verts[3], verts[2], verts[4], cols[all_hit])

		render.DrawWireframeBox(pos, ang, mins, maxs, color_white)
	else
		local b1, b2 = self:GetBound1(), self:GetBound2()
		local mins = b1
		local maxs = b2
		OrderVectors(mins, maxs)
		render.DrawWireframeBox(pos, ang, self:GetBound1(), self:GetBound2(), color_white)

		-- print(b1, b2)
		vReuse[2], vReuse[3], vReuse[1], vReuse[4] = math.abs(b1.y), math.abs(b1.z), math.abs(b2.y), math.abs(b2.z)
		local vertDist = vReuse

		render.SetMaterial(mat)
		mins.x = 0
		maxs.x = 0

		mtrx:Reset()
		mtrx:SetAngles(ang)
		mtrx:SetTranslation(pos)
		local boxDist = vertDist[3] + vertDist[4]
		local sc = boxDist / 36.785

		scl.x = 1
		scl.z = sc
		mtrx:SetScale(scl)

		mins.z = mins.z / sc
		mtrx:Translate(mins)

		mtrx:RotateNumber(0, 90, 0)

		cam.PushModelMatrix(mtrx)
			self.DoorMeshes[3]:Draw()
		cam.PopModelMatrix()


		maxs.z = maxs.z / sc

		mtrx:Reset()
		mtrx:SetAngles(ang)
		mtrx:SetTranslation(pos)
		mtrx:SetScale(scl)

		mtrx:Translate(maxs)
		mtrx:RotateNumber(0, -90, 180)

		cam.PushModelMatrix(mtrx)
			self.DoorMeshes[3]:Draw()
		cam.PopModelMatrix()

		mtrx:Reset()
		mtrx:SetAngles(ang)
		mtrx:SetTranslation(pos)
		mtrx:SetScale(scl)

		mtrx:Translate(maxs)
		mtrx:RotateNumber(0, -90, 180)

		cam.PushModelMatrix(mtrx)
			self.DoorMeshes[3]:Draw()
		cam.PopModelMatrix()

		scl.x = math.abs(self.RightClose * (vertDist[1] - 6.66) / 1.344) -- wtf

		mtrx:Reset()

		mtrx:Translate(pos)
		mtrx:Rotate(ang)

		mtrx:Scale(scl)
		mtrx:Translate(maxs - magicOffset)
		mtrx:SetScaleNumber(1, 1, 1)	-- yuck

		mtrx:RotateNumber(180, 90, 0)

		mtrx:Scale(scl)

		render.SetMaterial(wf)

		cam.PushModelMatrix(mtrx)
			self.DoorMeshes[2]:Draw()
		cam.PopModelMatrix()

		scl.x = math.abs(self.LeftClose * (vertDist[2] - 6.66) / 1.344)

		mtrx:Reset()

		mtrx:Translate(pos)
		mtrx:Rotate(ang)

		mtrx:Scale(scl)
		mtrx:Translate(mins + magicOffset)
		mtrx:SetScale(Vector(1, 1, 1))	-- yuck

		mtrx:RotateNumber(0, 90, 0)

		mtrx:Scale(scl)


		cam.PushModelMatrix(mtrx)
			self.DoorMeshes[2]:Draw()
		cam.PopModelMatrix()
	end
end


function ENT:Think()

end