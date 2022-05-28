AddCSLuaFile()

ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "BW Base Entity"

ENT.Model = "models/props_interiors/pot02a.mdl"
ENT.Skin = 0
ENT.PresetMaxHealth = 100

ENT.IsBaseWars = true

ENT.Level = 1
ENT.WantBlink = true

ENT.UsesModules = false
ENT.ModuleSlots = 3


function ENT:SVInit() end
function ENT:CLInit() end
function ENT:SHInit() end
function ENT:Init() end

function ENT:ThinkFunc() end
function ENT:UseFunc() end


function ENT:DerivedDataTables() end

function ENT:ForceUpdate()
	self.TransmitTime = CurTime()
end

function ENT:GetMaxLevel()
	return math.max( (self.Levels and #self.Levels or 0), self.MaxLevel or 0 )
end

function ENT:UpdateTransmitState()
	if not self.TransmitTime or CurTime() - self.TransmitTime < 0.5 then
		self.TransmitTime = self.TransmitTime or CurTime()
		return TRANSMIT_ALWAYS
	end
	return TRANSMIT_PVS
end

function ENT:BadlyDamaged()

	return self:Health() <= (self:GetMaxHealth() / 5)

end

function ENT:GetPower()
	return true
end

function ENT:SetupDataTables()
	self:DerivedDataTables()
end

function ENT:SHInit()

end

if SERVER then

	function ENT:Initialize()
		self:SetModel(self.Model)
		self:SetSkin(self.Skin)

		if SERVER then
			self:PhysicsInit(SOLID_VPHYSICS)
			self:SetSolid(SOLID_VPHYSICS)
			self:SetMoveType(MOVETYPE_VPHYSICS)

			self:SetUseType(SIMPLE_USE)
			if self.WantBlink then
				self:AddEffects(EF_ITEM_BLINK)
			end

			self:PhysWake()
			self:Activate()
		end

		self:SetHealth(self.PresetMaxHealth or self.MaxHealth)

		self:Init(me)
		self:SHInit()
		self:SVInit()

		self:SetMaxHealth(self:Health())

		timer.Simple(0.5, function()
			if IsValid(self) then self:RemoveEFlags(EFL_FORCE_CHECK_TRANSMIT) end
		end)

		if self.SubModels then
			for k,v in ipairs(self.SubModels) do
				local prop = ents.Create("prop_physics")
				prop:SetPos(self:LocalToWorld(v.Pos or Vector()))
				prop:SetAngles(self:LocalToWorldAngles(v.Ang or Angle()))
				prop:SetModel(v.Model or "models/Gibs/HGIBS.mdl")
				prop:SetSkin(v.Skin or 0)
				prop:SetParent(self)
				if v.Material then
					prop:SetMaterial(v.Material)
				end
			end
		end

		self:SetHealth(self.PresetMaxHealth or self.MaxHealth)
		self:SetMaxHealth(self:Health())

		self:InitModuleInventory()

		self:Init(me)
		self:SHInit()
	end

	function FillSubModelData(ent)
		local t = {}
		for k,v in ipairs(ent:GetChildren()) do
			t[#t + 1] = {
				Pos = v:GetLocalPos(),
				Ang = v:GetLocalAngles(),
				Model = v:GetModel(),
				Skin = (v:GetSkin() ~= 0 and v:GetSkin()) or nil,
				Material = (v:GetMaterial() ~= 0 and v:GetMaterial()) or nil
			}
		end

		return t
	end

	function ENT:Repair()
		self:SetHealth(self:GetMaxHealth())
	end

	function ENT:Spark(a, ply)
		local vPoint = self:GetPos()
		local effectdata = EffectData()

		effectdata:SetOrigin(vPoint)
		util.Effect(a or "ManhackSparks", effectdata)
		self:EmitSound("DoSpark")

		if ply and ply:GetPos():Distance(self:GetPos()) < 80 and math.random(0, 10) == 0 then
			local d = DamageInfo()

			d:SetAttacker(ply)
			d:SetInflictor(ply)
			d:SetDamage(ply:Health() / 2)
			d:SetDamageType(DMG_SHOCK)

			vPoint = ply:GetPos()
			effectdata = EffectData()

			effectdata:SetOrigin(vPoint)
			util.Effect(a or "ManhackSparks", effectdata)

			ply:TakeDamageInfo(d)
		end
	end

	function ENT:OnTakeDamage(dmginfo)
		local dmg = dmginfo:GetDamage()
		local Attacker = dmginfo:GetAttacker()

		self:SetHealth(self:Health() - dmg)

		if self:Health() <= 0 and not self.BlownUp then

			self.BlownUp = true

			xpcall(BaseWars.UTIL.PayOut, GenerateErrorer("EntBase Payout"), self, Attacker)

			if dmginfo:IsExplosionDamage() then
				self:Explode(false)
				return
			end

			self:Explode()

			return
		end

		if dmginfo:GetDamage() < 1 then return end

		self:Spark(nil, Attacker)

	end

	function ENT:Explode(e)

		if e == false then
			local vPoint = self:GetPos()
			local effectdata = EffectData()
			effectdata:SetOrigin(vPoint)
			util.Effect("Explosion", effectdata)

			self:Remove()
			return
		end

		local ex = ents.Create("env_explosion")
			ex:SetPos(self:GetPos())
		ex:Spawn()
		ex:Activate()

		ex:SetKeyValue("iMagnitude", 100)

		ex:Fire("explode")

		self:Spark("cball_bounce")
		self:Remove()

		SafeRemoveEntityDelayed(ex, 0.1)

	end

else

	function ENT:Initialize()
		self:InitModuleInventory()

		self:Init()
		self:SHInit()
		self:CLInit()
	end

	function ENT:Mod_GenerateCompatible(f, scr, ipnl)
		-- for override
	end

	function ENT:Mod_RequestInstall(install, slot)
		-- install = false for uninstallation
		print("Mod_RequestInstall", install, slot)

		net.Start("bw_base_module")
			net.WriteEntity(self)
			net.WriteBool(install)
			net.WriteUInt(slot, 8)
		net.SendToServer()
	end

	function ENT:Mod_ShowCompatible(f, ipnl)
		local cat = vgui.Create("FCategory", ipnl)
		cat:Dock(TOP)
		cat:SetText("Available Modules")

		ipnl:InvalidateLayout(true)
		cat:SetExpandHeight(ipnl.SlotBottom - (cat:GetTall() + cat.Y) - 4)

		local scr = cat:Add("FScrollPanel")
		scr:Dock(FILL)
		scr:SetTall(cat:GetExpandHeight())
		scr:SetShouldDraw(false)

		-- bro
		cat:InvalidateLayout(true)
		cat:GetCanvas():InvalidateLayout(true)
		cat:GetCanvas():InvalidateChildren(true)

		self:Mod_GenerateCompatible(f, scr, ipnl)

		return cat
	end

	function ENT:Mod_CreateInstallButton(ipnl, slCanv)
		local ent = self
		local inst = vgui.Create("FButton", slCanv)
		local slot = slCanv.Slot

		inst:SetSize(slCanv:GetWide(), 28)
		inst:SetPos(0, slot.Y - 8 - inst:GetTall())

		function inst:DoClick()
			ent:Mod_RequestInstall(true, slot:GetSlot())
		end

		function inst:Think()
			if not slot:GetItem(true) then
				self:SetEnabled(false)
				return
			end

			self:SetEnabled(true)
			self:SetColor(Colors.Sky)
		end

		return inst
	end

	function ENT:Mod_CreateModuleMenu(plyInv)
		local scale, scaleW = Scaler(1600, 900, true)

		local f = vgui.Create("FFrame")
		f:SetSize(scaleW(450), plyInv:GetTall())

		local ipnl = vgui.Create("InventoryPanel", f)
		ipnl:Dock(FILL)
		ipnl:EnableName(false)
		ipnl:SetShouldPaint(false)
		ipnl:SetInventory(self.Modules)

		f:InvalidateLayout(true)

		local slots = {}
		local slotCanvs = {}
		local slotH = 0

		for i=1, self.ModuleSlots do
			local canv = vgui.Create("InvisPanel", ipnl)
			canv:SetSize(96, 160)

			local slot = vgui.Create("ItemFrame", canv, "ItemFrame: ModuleSlot")
			slot:SetPos(canv:GetWide() / 2 - slot:GetWide() / 2, canv:GetTall() - slot:GetTall())
			canv.Slot = slot

			canv.Install = self:Mod_CreateInstallButton(ipnl, canv)

			ipnl:TrackItemSlot(slot, i)

			slots[i] = slot
			slotCanvs[i] = canv
			slotH = slot:GetTall()
		end

		f.ModuleSlots = slots
		f.ModuleSlotCanvs = slotCanvs

		ipnl.SlotBottom = ipnl:GetTall() - slotH
		ipnl.SlotTop = ipnl:GetTall() - slotH - 32

		local pos, tW = vgui.Position(scaleW(24), unpack(slotCanvs))

		for canv, x in pairs(pos) do
			canv:SetPos(
				ipnl:GetWide() / 2 - tW / 2 + x,
				ipnl.SlotTop - (canv:GetTall() - canv.Slot.Y))
		end

		local cat = self:Mod_ShowCompatible(f, ipnl)
		cat:On("ExpandChanged", "MoveSlots", function(_, ex)
			local y = ex and ipnl.SlotBottom or ipnl.SlotTop

			for _, slot in pairs(slotCanvs) do
				slot:MoveTo(slot.X, y, 0.2, 0, 0.3)
			end
		end)
		return f
	end

	function ENT:Mod_AnimateMenus(f, inv)
		local pos, tW = vgui.Position(8, f, inv)
		local x = ScrW() / 2 - tW / 2

		for pnl, nx in pairs(pos) do
			local offX = nx + pnl:GetWide() / 2 < tW / 2 and 16 or -16
			pnl:SetPos(x + nx + offX, ScrH() / 2 - pnl:GetTall() / 2)
			pnl:MoveBy(-offX, 0, 0.3, 0, 0.3)
		end
	end

	function ENT:Mod_OpenMenu()
		if IsValid(self._modPlyInv) then self._modPlyInv:Remove() end

		local inv = Inventory.Panels.CreateInventory(LocalPlayer().Inventory.Backpack, nil, {
			SlotSize = 64
		})

		inv:Bond(self)
		inv:MakePopup()
		inv:ShrinkToFit()

		self._modPlyInv = inv
		local ent = self

		local f = self:Mod_CreateModuleMenu(inv)
		inv:Bond(f)
		f:Bond(inv)

		self:Mod_AnimateMenus(f, inv)
	end
end

function ENT:InitModuleInventory()
	if not self.UsesModules then return end

	self.Inventory = {Inventory.Inventories.Entity:new(self)}

	self.InstalledModules = {}

	self.Modules = self.Inventory[1]
	self.Modules.MaxItems = self.ModuleSlots
	self.Modules.UseOwnership = true

	self.Modules.ActionCanCrossInventoryFrom = function(inv, ply, ...)
		return self:Mod_CanFrom(ply, ...)
	end

	self.Modules.ActionCanCrossInventoryTo = function(inv, ply, ...)
		return self:Mod_CanTo(ply, ...)
	end

	self.Modules:On("AllowInteract", "BaseHook", function(inv, ...)
		return self:Mod_AllowInteract(...)
	end)

	self.Modules.SupportsSplit = false
end

-- for override
function ENT:Mod_Compatible(ply, itm)
	print("ENT:Mod_Compatible not overridden. Returning false.")
	return false
end

function ENT:Mod_CanTo(ply, itm, fromInv)
	if not Inventory.IsModule(itm) then return false end
	if not fromInv.IsBackpack then return false end

	if not self:Mod_Compatible(ply, itm) then
		return false
	end

	return true
end

function ENT:Mod_CanFrom(ply, itm, toInv)
	if not toInv.IsBackpack then return false end
	if self.InstalledModules[itm] then return false end

	return true
end

function ENT:Mod_AllowInteract(ply, act)
	if not self:BW_IsOwner(ply) then return false end
	if not ply:Alive() then return false end
	if ply:EyePos():Distance(self:LocalToWorld(self:OBBCenter())) > 128 then return false end

	return true
end

if SERVER then
	function ENT:OnInstalledModule(slot, itm) end
	function ENT:OnUninstalledModule(slot, itm) end

	function ENT:Mod_Install(slot, itm)
		self.InstalledModules[itm] = slot
		self.InstalledModules[slot] = itm

		self:OnInstalledModule(slot, itm)
	end

	function ENT:Mod_Uninstall(slot, itm)
		self.InstalledModules[itm] = nil
		self.InstalledModules[slot] = nil

		self:OnUninstalledModule(slot, itm)
	end

	function ENT:Mod_RequestInstall(install, ply, slot)
		if not self:Mod_AllowInteract(ply, install and "Install" or "Uninstall") then return end

		local itm = self.Modules:GetItemInSlot(slot)
		if not itm then print("no itm?", slot, itm) return end

		local installed = self.InstalledModules[itm]

		if install == (not not installed) then
			print("mismatched states; ignoring")
			return
		end

		if install then
			self:Mod_Install(slot, itm)
		else
			self:Mod_Uninstall(slot, itm)
		end
	end

	util.AddNetworkString("bw_base_module")

	net.Receive("bw_base_module", function(_, ply)
		local ent = net.ReadEntity()
		if not IsValid(ent) or not ent.UsesModules or not ent.Modules then return end

		ent:Mod_RequestInstall(net.ReadBool(), ply, net.ReadUInt(8))
	end)
end