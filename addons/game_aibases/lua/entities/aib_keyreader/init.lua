include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

util.AddNetworkString("aib_keyreader")

function ENT:Init(me)
	WireLib.CreateOutputs(self, {"KeycardUsed", "OpenState"})
end

function ENT:Think()
	self:NextThink(CurTime() + 1)
	return true
end

function ENT:Use(ply)

end

function ENT:EmitSignal()
	Wire_TriggerOutput(self, "KeycardUsed", 1)
	Wire_TriggerOutput(self, "KeycardUsed", 0)

	Wire_TriggerOutput(self, "OpenState", 1)
	self:Close()
end

function ENT:Open()
	Wire_TriggerOutput(self, "OpenState", 1)
	self:SetOpened(true)
end

function ENT:Close()
	Wire_TriggerOutput(self, "OpenState", 0)
	self:SetOpened(false)
end

function ENT:SwipeCard(ply, itm, inv)
	self:Timer("CardReply", 0.2, 1, function()
		sound.Play("grp/keycards/yes.wav", self:GetSwipePos(), 70, 100, 1)
		self.LockedUse = false
		self:Open()

		self:Timer("CardEmit", 1, 1, function()
			self:EmitSignal()
		end)
	end)
end

function ENT:UseCard(ply, itm, inv)
	if self.LockedUse then return end
	if self:GetOpened() then return end

	local ping = ply:Ping() -- just a little qol
	local del = 0.7 - ping / 1000

	self.LockedUse = true
	self:SetInsertTime(CurTime())

	self:Timer("UseCard", del, 1, function()
		self:Timer("CardBleep", 0.6, 1, function()
			sound.Play("grp/keycards/inter2.ogg", self:GetSwipePos(), 70, 100, 0.8)
			self:SwipeCard(ply, itm, inv)
		end)

		sound.Play("grp/keycards/swipe.wav", self:GetSwipePos(), 65, 100, 1)
	end)
end

net.Receive("aib_keyreader", function(len, ply)
	local uid = net.ReadUInt(32)
	local ent = net.ReadEntity()

	local itm, inv

	for k,v in pairs(Inventory.Util.GetUsableInventories(ply)) do
		local card = v:GetItem(uid)
		if card then
			itm = card
			inv = v
			break
		end
	end

	if not itm then
		print(ply, "didn't find card to use for", ent)
		return
	end

	if not IsValid(ent) or not ent.IsAIKeyReader then
		print("bad ent", ent)
		return
	end

	if ent.LockedUse then
		print("locked ent", ent)
		return
	end

	local dist = ent:GetPos():Distance(ply:EyePos())
	if dist > 192 then
		print("too far", ply, ent)
		return
	end

	ent:UseCard(ply, itm, inv)
end)