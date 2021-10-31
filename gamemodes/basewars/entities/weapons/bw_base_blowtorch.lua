AddCSLuaFile()

SWEP.PrintName 	= "Blowtorch T???"
SWEP.Author = "grmx"
SWEP.Instructions = "Destroy others' props in a raid."

SWEP.Spawnable = true
SWEP.AdminSpawnable = false

SWEP.ViewModelFOV = 65
SWEP.ViewModel 	= "models/weapons/v_superphyscannon.mdl"
SWEP.WorldModel = "models/weapons/w_rocket_launcher.mdl"
SWEP.UseHands = true

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 5
SWEP.SlotPos = 1

SWEP.HoldType = "ar2"
SWEP.FiresUnderwater = true
SWEP.Weight = 20
SWEP.DrawCrosshair = true

SWEP.Category = "BaseWars"
SWEP.DrawAmmo = false
SWEP.Base = "weapon_base"

SWEP.Primary.Damage = 0
SWEP.Primary.ClipSize = -1
SWEP.Primary.Ammo = "none"
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Spread = 0.25
SWEP.Primary.NumberofShots = 1
SWEP.Primary.Automatic = true
SWEP.Primary.Delay 	= 0.25
SWEP.Primary.Force 	= 1

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"

SWEP.Sounds = {
	"ambient/energy/spark1.wav",
	"ambient/energy/spark2.wav",
	"ambient/energy/spark3.wav",
	"ambient/energy/spark4.wav",
	"ambient/energy/spark5.wav",
	"ambient/energy/spark6.wav"
}

SWEP.Range = 80
SWEP.Penetrates = 3
SWEP.TorchDamage = 20
SWEP.IsBlowTorch = true

local function IsProp(ent)
	return IsValid(ent) and (
		(ent.GetClass and ent:GetClass() == "prop_physics") or
		(ent.CanBlowtorch and true) or false
	)
end

local function IsOwned(ent)
	return IsValid(ent) and ent:BW_GetOwner() and
		(not ent.IsBasewars or ent.CanBlowtorch)
end

function SWEP:Deploy()
	-- self:SendWeaponAnim(ACT_VM_IDLE)
end

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

local function GetHP(prop)
	return prop:Health()
end

local function GetMaxHP(prop)
	return math.max(prop:GetMaxHealth(), 1)
end

local function SetHP(prop, hp)
	if hp <= 0 then
		prop:Remove()
		return
	end

	prop:SetHealth(hp)
	prop:SetNWFloat("LastDamage", CurTime()) -- ew nwvars
end

function SWEP:Zap()
	self:EmitSound(self.Sounds[math.random(#self.Sounds)],
		90, math.random(90, 110), 1)
end

local function isZappable(self, ent)
	-- world non-prop
	if not IsProp(ent) and not IsOwned(ent) then return false end

	-- either a world prop or an owned entity; can blowtorch
	return ent:BW_GetOwner()
end

local function canZap(self, ent, dmg)
	if not IsProp(ent) and not IsOwned(ent) then return false end

	return BaseWars.Raid.CanBlowtorch(self:GetOwner(), ent, self, dmg)
end

function SWEP:PrimaryAttack()
	local ply = self:GetOwner()
	if not IsPlayer(ply) then return end

	-- bruh!!!!
	local tr = util.TraceHull({
		start = ply:EyePos(),
		endpos = ply:EyePos() + (ply:GetAimVector() * self.Range),
		maxs = vector_origin,
		mins = vector_origin,
		filter = {ply}
	})

	local trent = tr.Entity

	local ow = isZappable(self, trent)

	if not ow then
		return
	end

	local dmg = DamageInfo()
	dmg:SetDamage(self.TorchDamage)
	dmg:SetAttacker(ply)
	dmg:SetInflictor(self)

	if not canZap(self, trent, dmg) then
		return
	end

	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)

	local snd = self.Sounds[math.random(#self.Sounds)]
	self:EmitSound(snd)

	if CLIENT then return end

	local trents = {ply, trent}

	self:Zap()

	--[[for i=1, self.Penetrates - 1 do
		local newtr = util.TraceLine({
			start = tr.StartPos,
			endpos = tr.StartPos + tr.Normal * self.Range,
			filter = trents,
		})

		if canZap(self, newtr.Entity) then
			trents[#trents + 1] = newtr.Entity
		end

	end]]

	table.remove(trents, 1)
	dmg = dmg:GetDamage()

	for k,v in ipairs(trents) do
		local hp = GetHP(v)
		hp = hp - dmg

		local frac = hp / GetMaxHP(v)
		v:SetColor( Color(255 * frac, 255 * frac, 255 * frac, v:GetColor().a) )

		SetHP(v, hp)
	end
end

function SWEP:SecondaryAttack()
	return false
end


if not CLIENT then return end

local lastent 		-- last valid ent we looked at
local x, y = 0, 0 	-- last valid pos of the ent


local strX, strY = 0, 0 --stripes
local hpfrac = 0

local anim

function SWEP:FillData(tr, ent, ow)
	local prev = lastent
	lastent = ent

	local trent = ent
	local new_trents = {LocalPlayer(), trent}

	--[[for i=1, self.Penetrates - 1 do 	-- -1 because trent is already 1
		local newtr = util.TraceLine({
			start = tr.StartPos,
			endpos = tr.StartPos + tr.Normal * self.Range,
			filter = new_trents,
		})

		if isZappable(self, newtr.Entity) then
			new_trents[#new_trents + 1] = newtr.Entity
		end
	end]]

	table.remove(new_trents, 1)
	trents = new_trents
	return prev ~= lastent
end

local CanRaidColor = Color(230, 100, 100)
local CantRaidColor = Color(150, 30, 30)

local hpBarCol = CantRaidColor:Copy()
local emptyBar = Colors.LightGray:Copy()

local infoCol = Color(40, 40, 40)
local txCol = Color(220, 220, 220)

local curBlowtorch
local frW, frH = 180, 55

local function paint(ent, curent, baseAnim, firstFrame)
	local self = curBlowtorch -- shut up linter
	if not curBlowtorch then return end

	anim = anim or Animatable("blowtorchhud")
	local ply = LocalPlayer()
	local tr = util.TraceHull({
		start = ply:EyePos(),
		endpos = ply:EyePos() + (ply:GetAimVector() * self.Range),
		maxs = vector_origin,
		mins = vector_origin,
		filter = {ply}
	})

	--stripes = (not MoarPanelsMats["stripes"]:IsError() and MoarPanelsMats["stripes"]) or errmat -- :/

	local ow = isZappable(self, ent)
	local canraid = canZap(self, ent) --IsPlayerInfo(ow) and ow:IsEnemy(LocalPlayer())

	if ow then
		self:FillData(tr, ent, ow)
	end

	if canraid then
		anim:LerpColor(hpBarCol, CanRaidColor, 0.3, 0, 0.3)
	else
		anim:LerpColor(hpBarCol, CantRaidColor, 0.3, 0, 0.3)
	end

	if a == 0 then return end

	local headerH = 18
	local w, h = frW, baseAnim.Height or frH

	BaseWars.HUD.PaintFrame(w, h, headerH)

	local hp, max = 1, 1

	hpfrac = anim.HPFrac or 0

	if ent then
		hp = GetHP(ent)
		max = GetMaxHP(ent)
		anim:To("HPFrac", hp / max, 0.2, 0, 0.3)
	end

	surface.SetDrawColor(emptyBar)
	local xpad = 12
	local barW, barH = w - xpad * 2, 16
	local barY = headerH + (h - headerH) / 2 - barH / 2

	surface.DrawRect(x + xpad, barY, barW, barH)

	draw.SimpleText("H E A L T H", "OSB20", x + xpad + barW / 2, barY + barH / 2, infoCol, 1, 1)

	if not canraid then
		draw.BeginMask()
		draw.SetMaskDraw(true)
	end

	surface.SetDrawColor(hpBarCol)
	surface.DrawRect(x + xpad, barY, hpfrac * barW, barH)

	if not canraid then
		draw.DisableMask()
	end

	draw.SimpleText(hp .. "/" .. max, "OS18",
		x + xpad + hpfrac * barW,
		barY + barH,
		txCol, 1, 5)

	if not canraid then
		strX = (strX + FrameTime() / 32) % 1
		strY = (strY + FrameTime() / 16) % 1

		surface.SetDrawColor(0, 0, 0, 150)

		draw.ReenableMask()
		draw.DrawOp()

		surface.DrawUVMaterial("https://i.imgur.com/y9uYf4Y.png", "whitestripes.png",
			x, y, 200, 80, 0.1 - strX, 0.1 - strY, 0.6 - strX, 0.4 - strY)
		draw.SimpleText("H E A L T H", "OSB18", x + xpad + barW / 2, math.floor(barY + barH / 2), txCol, 1, 1)

		draw.FinishMask()
	end

	if canraid then
		--local str = ("penetrates %s prop%s"):format(#trents, (#trents ~= 1 and "s") or "")
		--draw.SimpleText(str, "OSB18", x + 100, math.floor(y) + 76, Color(200, 200, 200, a), 1, 4)
	end

	baseAnim:To("Height", frH, 0.3, 0, 0.3)
end

local function framePos(ent, trace, ep)
	-- holding primary fire caches a predicted/compensated trace i think
	-- this fucks up the hud and makes it all jittery
	-- so we fire a new trace instead of using the cached :GetEyeTrace

	local ply = LocalPlayer()

	local tr = util.TraceHull({
		start = ply:EyePos(),
		endpos = ply:EyePos() + (ply:GetAimVector() * 192),
		maxs = vector_origin,
		mins = vector_origin,
		filter = {ply}
	})

	return tr.HitPos + Vector(0, 0, 8)
end

--hook.Add("BW_PaintStructureInfo", "Blowtorch", paint)

hook.Add("BW_ShouldPaintStructureInfo", "Blowtorch", function(ent, dist)
	local wep = LocalPlayer():GetActiveWeapon()
	local wep_ok = wep.IsBlowTorch

	if not wep_ok or dist > 192 then return end

	local class_ok = isZappable(wep, ent)
	if not class_ok then return end

	curBlowtorch = wep

	return true, 192, paint, framePos
end)