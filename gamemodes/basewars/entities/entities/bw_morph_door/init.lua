include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

function ENT:Init(me)
	WireLib.CreateInputs(self,
		{
			"Open",
			"Close",
			"State",
			"Unlock",
			"Lock",
			"UnlockState",
		},

		{
			"Open on signal",
			"Close on signal",
			"Change state to signal",
			"Permit opening the door by using it (default: locked)",
			"Forbid opening the door by using it",
			"Change unlocked state to signal (1 = unlocked)"
		}
	)

	self.Locked = true
end

function ENT:Think()

end

function ENT:Install()
	self:CreateCollision()
	self:SetInstalled(true)
	self.HasPhysics = true
end

function ENT:Wire_Open(val)
	if val > 0 then
		self:OpenState(true)
	end
end

function ENT:Wire_Close(val)
	if val > 0 then
		self:OpenState(false)
	end
end

function ENT:Wire_State(val)
	self:OpenState(val > 0)
end

function ENT:Wire_Unlock(val)
	if val > 0 then
		self.Locked = false
	end
end

function ENT:Wire_Lock(val)
	if val > 0 then
		self.Locked = true
	end
end

function ENT:Wire_LockState(val)
	self.Locked = val <= 0
end

function ENT:TriggerInput(sig, val)
	if not self["Wire_" .. sig] then
		errorNHf("missing handler: Wire_%s", sig)
		return
	end

	self["Wire_" .. sig] (self, val)
end

function ENT:Open()
	self:Emit("Opened")
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	self:SetOpen(true)
end

function ENT:Close()
	self:CreateCollision()
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:SetOpen(false)
end

function ENT:OpenState(open)
	if open then
		self:Open()
	else
		self:Close()
	end
end

function ENT:Use(ply)
	if not self.HasPhysics then
		self:Install()
		return
	end

	if not self.Locked then
		self:OpenState(not self:GetOpen())
	end
end

function ENT:Think()
	if self.HasPhysics then
		local phys = self:GetPhysicsObject()
		if phys and phys:IsValid() then
			phys:EnableMotion(false)
		end
	end
end