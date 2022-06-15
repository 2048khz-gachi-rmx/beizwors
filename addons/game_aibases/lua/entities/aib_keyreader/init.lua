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
	Wire_TriggerOutput(self, "OpenState", self:GetOpened() and 1 or 0)
end

function ENT:Open(nosig)
	self:SetOpened(true)
	if not nosig then self:EmitSignal() end
end

function ENT:Close(nosig)
	self:SetOpened(false)
	if not nosig then self:EmitSignal() end
end

function ENT:SwipeCard(ply, itm, inv)
	self:Timer("CardReply", 0.2, 1, function()
		local ok = self:CardValid(itm)

		if ok then
			self:Emit("UsedValidCard", ply, itm)
		else
			self:Emit("UsedInvalidCard", ply, itm)
		end

		sound.Play(("grp/keycards/%s.mp3"):format(ok and "yes" or "no"), self:GetSwipePos(), 70, 100, 1)
		self.LockedUse = false

		if ok then
			self:Open(true)

			self:Timer("CardEmit", 1, 1, function()
				Wire_TriggerOutput(self, "KeycardUsed", 1)
				Wire_TriggerOutput(self, "KeycardUsed", 0)
				self:EmitSignal()

				self:Timer("debug", 3, 1, function() self:Close() end)
			end)
		end
	end)
end

function ENT:UseCard(ply, itm, inv)
	if self.LockedUse then return end
	if self:GetOpened() then return end

	local ping = ply:Ping() -- just a little qol
	local del = 0.7 - ping / 1000

	self.LockedUse = true
	self:SetInsertTime(CurTime())

	local ok = self:CardValid(itm)

	if ok then
		self:Emit("StartUsingValidCard", ply, itm)
	else
		self:Emit("StartUsingInvalidCard", ply, itm)
	end

	self:Timer("UseCard", del, 1, function()
		self:Timer("CardBleep", 0.6, 1, function()
			sound.Play("grp/keycards/inter2.ogg", self:GetSwipePos(), 70, 100, 0.8)
			self:SwipeCard(ply, itm, inv)
		end)

		sound.Play("grp/keycards/swipe.mp3", self:GetSwipePos(), 65, 100, 1)
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