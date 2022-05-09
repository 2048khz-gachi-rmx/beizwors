include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

function ENT:Init(me)
	WireLib.CreateInputs(self,
		{"Open", "Close", "State"},
		{"Open on signal", "Close on signal", "Change state to signal"}
	)
end

function ENT:Think()

end

function ENT:Install()
	self:CreateCollision()
	self:SetInstalled(true)
	self.HasPhysics = true
end

function ENT:TriggerInput(sig, val)
	if sig == "Open" then
		if val > 0 then
			self:OpenState(true)
		end
	elseif sig == "Close" then
		if val > 0 then
			self:OpenState(false)
		end
	else
		self:OpenState(val > 0)
	end
end

function ENT:Open()
	self:Emit("Opened")
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self:SetOpen(true)
end

function ENT:Close()
	self:CreateCollision()
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:SetOpen(false)
end

function ENT:OpenState(open)
	if open then self:Open() else self:Close() end
end

function ENT:Use(ply)
	if self.HasPhysics then
		self:OpenState(not self:GetOpen())
		return
	end

	self:Install()
end

function ENT:Think()
	if self.HasPhysics then
		local phys = self:GetPhysicsObject()
		if phys and phys:IsValid() then
			phys:EnableMotion(false)
		end
	end
end