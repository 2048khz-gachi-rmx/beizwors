include("shared.lua")
include("death_drop.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

util.AddNetworkString("PlayerlootOpen")

function ENT:SV_Init(me)
	local ent = self

	self.Storage:On("RemovedItem", "RemoveCrate", function(self)
		if table.IsEmpty(self:GetItems()) then
			ent:Remove()
		end
	end)
end

function ENT:Think()
	self:NextThink(CurTime() + 1)
	return true
end

function ENT:Use(ply)
	Inventory.Networking.NetworkInventory(ply, self.Storage, INV_NETWORK_UPDATE)

	net.Start("PlayerlootOpen")
		net.WriteEntity(self)
	net.Send(ply)
end

function ENT:OnRemove()
	for k,v in pairs(self.Storage:GetItems()) do
		v:Delete()
	end
end


local crap = {"copper_ore", "gold_ore", "gold_bar", "laserdiode", "tgt_finder", "stem_cells"}

function DebugMakeLoot()
	local amt = math.random(3, Inventory.Inventories.Backpack.MaxItems)

	local prs = {}

	for i=1, amt do
		local pr = Promise()
		table.insert(prs, pr)

		local iid = table.Random(crap)
		local base = Inventory.Util.GetBase(iid)
		local iamt = base:GetMaxStack()

		local itm = Inventory.NewItem(iid)
		itm:SetAmount(math.random(1, iamt))

		pr.Item = itm
		Inventory.MySQL.NewFloatingItem(itm):Then(pr:Resolver())
	end

	Promise.OnAll(prs):Then(function()
	 	local loot = ents.Create("bw_playerloot")
		loot:Spawn()

		local rcol = Color(0, 0, 0)
		rcol:SetHSV(math.random() * 360, Lerp(math.random(), 0.3, 0.7), Lerp(math.random(), 0.5, 0.7))

		loot:SetColor(rcol)
		for k,v in ipairs(prs) do
			local it = v.Item
			it:SetSlot(k)
			loot.Storage:AddItem(it, true)
		end

		local p = player.GetHumans()[1]
		loot:SetPos(p:GetEyeTrace().HitPos + Vector(0, 0, 16))

		return 0
	end)
end
