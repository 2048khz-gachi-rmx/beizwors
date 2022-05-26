AddCSLuaFile()

ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "BW Template Entity"

ENT.Model = "models/props_interiors/pot02a.mdl"
ENT.Skin = 0
ENT.PresetMaxHealth = 100

ENT.IsBaseWars = true

ENT.Level = 1


function ENT:ThinkFunc() end
function ENT:UseFunc() end

function ENT:PreInit() end

function ENT:SVInit() end
function ENT:SHInit() end
function ENT:CLInit() end

if SERVER then

	function ENT:Initialize()
		self:PreInit()

		if self.Model then
			self:SetModel(self.Model)
		end

		if self.Skin then
			self:SetSkin(self.Skin)
		end

		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)

		self:SetUseType(SIMPLE_USE)

		self:PhysWake()
		self:Activate()

		self:SVInit(me)
		self:SHInit()
	end

else
	function ENT:CLInit()

	end

	function ENT:Initialize()
		self:CLInit()
		self:SHInit()
	end
end
