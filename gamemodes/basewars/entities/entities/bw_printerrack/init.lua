AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local max = 8 --max printers

function ENT:Init()
	self.Money = 0

	self:SetHealth(self.PresetMaxHealth or 100)

	self.Printers = Networkable(("PrinterRack:%d"):format(self:EntIndex())):Bond(self)
	self.Printers.Entities = {}
end

--[[local pos = {
	Vector (0.912353515625, -0.44677734375, 13.148170471191),
	Vector (0.912353515625, -0.44677734375, 13.148170471191 + 6.25),
	Vector (0.912353515625, -0.44677734375, 13.148170471191 + 6.25*2),
	Vector (0.912353515625, -0.44677734375, 13.148170471191 + 6.25*3 - 0.2),
	Vector (0.912353515625, -0.44677734375, 13.148170471191 + 6.25*4 - 0.4),

	Vector (0.912353515625, -0.44677734375, 13.148170471191 + 6.25*6 - 0.9),
	Vector (0.912353515625, -0.44677734375, 13.148170471191 + 6.25*7 - 1),
	Vector (0.912353515625, -0.44677734375, 13.148170471191 + 6.25*8 - 1.1),
	Vector (0.912353515625, -0.44677734375, 13.148170471191 + 6.25*9 - 1.1),
	Vector (0.912353515625, -0.44677734375, 13.148170471191 + 6.25*10 - 1.1),
}]]

local pos = {}


for i=1, 8 do
	local off = i * 5.9 + (i >= 5 and 13 or 0)

	pos[#pos + 1] = Vector(3, -0.5, 8 + off)
end


function ENT:NetworkPrinters()
	for k,v in pairs(self.Printers.Entities) do
		self.Printers:Set(k, v:EntIndex())
	end
end

function ENT:AddPrinter(slot, ent)

	if not pos[slot] then error('attempted adding a printer to a slot which doesnt have a pos (' .. slot .. ")") return end

	self.Printers.Entities[slot] = ent

	local off = pos[slot]

	local pos = self:GetPos()
	local ang = self:GetAngles()

	pos = pos + ang:Up() * off.z
	pos = pos + ang:Right() * off.y
	pos = pos + ang:Forward() * off.x

	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent:SetMoveType(MOVETYPE_NONE)
	ent:SetParent(self)
	ent:SetPrinterRack(self)
	ent.IsInRack = true

	self:OverclockPrinters()
	self:NetworkPrinters()
end

function ENT:Touch(ent)
	if not ent.IsPrinter or ent.IsInRack or ent:BW_GetOwner() ~= self:BW_GetOwner() then
		return
	end

	local printers = self.Printers.Entities
	if table.Count(printers) >= max then return end

	local fr = 0

	for i=1, max do
		if not printers[i] then fr = i break end
	end

	if fr==0 then error('no free key for printer!') end

	self:AddPrinter(fr, ent)
end

function ENT:ThinkFunc()
	self:NetworkPrinters()
end

function ENT:OverclockPrinters()
	local ovk
	for k,v in pairs(self.Modules:GetItems()) do
		if v:GetItemName() == "overclocker" and v:GetInstalled() then
			ovk = v
			break
		end
	end

	if not ovk then
		print("no overclocker; clocking to 1")
		for k,v in pairs(self.Printers.Entities) do
			if not IsValid(v) then continue end

			v:Overclock(1)
		end

		return
	end

	local mult = ovk:GetBase().GetStrength(ovk)

	for k,v in pairs(self.Printers.Entities) do
		if not IsValid(v) then continue end

		v:Overclock(mult)
	end
	print("mult:", mult)
end

function ENT:OnInstalledModule(slot, itm)
	self:OverclockPrinters()
end

function ENT:OnUninstalledModule(slot, itm)
	self:OverclockPrinters()
end

function ENT:OnRemove()
	local zones = {}

	for k,v in pairs(self.Printers.Entities) do
		if not IsValid(v) then continue end

		v.IsInRack = false
		v:SetPrinterRack(NULL)
		v:SetParent()
		local phys = v:GetPhysicsObject()

		if IsValid(phys) then
			phys:EnableGravity(true)
		end

		v:SetMoveType(MOVETYPE_VPHYSICS)
		v:SetLocalAngularVelocity(Angle())
		v:SetAbsVelocity(Vector())
		v:SetPos(v:GetPos())

		if v:BW_GetZone() then
			zones[v:BW_GetZone()] = true
		end
	end

	for k,v in pairs(zones) do
		-- ewww
		timer.Simple(engine.TickInterval() * 4, function()
			k:RescanEnts()
		end)
	end
end

function ENT:Eject(num)
	local me = self:GetTable()

	if not me.Printers.Entities[num] then print("no printer!", num) return end

	local ent = me.Printers.Entities[num]
	if not ent or not IsValid(ent) then print('not valid') return end

	local mins = ent:OBBMins()
	local maxs = ent:OBBMaxs()

	mins, maxs = ent:GetRotatedAABB(mins, maxs)

	OrderVectors(mins, maxs)

	local ang = self:GetAngles()

	local startpos = ent:GetPos()
	local dir = ang:Forward()
	local len = 64

	local ignore = table.KeysToValues({self, ent})

	table.Add(ignore, me.Printers.Entities)

	local tr = util.TraceHull( {
		start = startpos,
		endpos = startpos + dir * len,
		maxs = maxs,
		mins = mins,
		filter = function(ent)
			return not (ignore[ent] or ent.IsPrinter)
		end
	} )

	if not tr.Hit then
		me.Printers.Entities[num] = nil
		me.Printers:Set(num, nil)

		ent.IsInRack = false

		ent:SetParent(nil)
		ent:SetPrinterRack(NULL)
		ent:SetMoveType(MOVETYPE_VPHYSICS)
		ent:SetPos(ent:GetPos() + ang:Forward() * 40)
		ent:Overclock(1)

		ent:SetGravity(1)

		local phys = ent:GetPhysicsObject()
		phys:EnableGravity(true) --???

		phys:SetVelocity(self:GetAngles():Forward() * 256)
		phys:SetAngleVelocity(Vector())

		if self:BW_GetZone() then
			self:BW_GetZone():RescanEnts()
		end
	else
		self:EmitSound("buttons/button10.wav", 65, 100, 1)
	end

end

util.AddNetworkString("PrinterRack")

net.Receive("PrinterRack", function(_, ply)
	local ent = net.ReadEntity()

	if not IsValid(ent) or
		ent:GetClass() ~= "bw_printerrack" or
		ply:GetPos():Distance(ent:GetPos()) > 192 or
		ent:BW_GetOwner() ~= ply:GetPInfo() then

		return
	end

	local typ = net.ReadUInt(2)

	if typ == 0 then
		local pr = net.ReadUInt(8)
		ent:Eject(pr)
	elseif typ == 1 then
		ent:Collect(ply)
	end

end)

function ENT:Use()
end

function ENT:Collect(ply)

	local moneys = 0

	for k,v in pairs(self.Printers.Entities) do
		if not IsValid(v) then continue end

		local mon = v.UseFunc and v:UseFunc(ply, ply, _, _, true)

		if mon then moneys = moneys + mon end
	end

	if moneys > 0 then ply:EmitSound("mvm/mvm_money_pickup.wav") end
end

