include("shared.lua")
AddCSLuaFile("shared.lua")

local wheel

local function makeWheel(ent)
	if wheel then wheel._Core = ent return wheel end

	local wh = LibItUp.InteractWheel:new()
	wh._Core = ent
	wheel = wh

	local base = ent:GetBase()

	local defOpt = BaseWars.Bases.Actions.GenerateWheel(wh, ent, base)

	wh:Show()

	if defOpt then
		wh:PointOnOption(defOpt)
	end

	return wh
end

local colThroughWalls = Colors.Sky:Copy():ModHSV(0, -0.1, -0.1)
local colObeyZ = Colors.Greenish:Copy():ModHSV(0, 0.1, 0.1)

function ENT:Initialize()
	self.Colors = {
		colThroughWalls:Copy(),
		colObeyZ:Copy()
	}

	self.HaloTable = {self}
	self.Claimed = false
	self.Using = 0
end

local useTime = 0

function ENT:Draw()
	self:DrawModel()

	if halo.RenderedEntity() == self then
		render.CullMode(1)
			self:DrawModel()
		render.CullMode(0)
		return
	end

	local lp = LocalPlayer()
	local myBaseID = self:GetBaseID()
	if not myBaseID then print(self, "has no fuckin base ID?") return end

	local base = BaseWars.Bases.GetBase(myBaseID)
	if not base then print(self, myBaseID, "didn't find base with that ID?") return end

	if lp:BW_GetBase() ~= base then return end

	local tr = lp:GetEyeTrace()
	local using = lp:KeyDown(IN_USE) and tr.Entity == self and tr.Fraction * 32768 < 96

	if using then
		self.Using = math.min(self.Using + FrameTime(), useTime)
	else
		self.Using = math.max(0, self.Using - FrameTime() * 2)
		if wheel and wheel._Core == self then
			wheel:Hide()
			wheel = nil
		end
	end

	if self.Using == useTime and not wheel and using then
		makeWheel(self)
	end
end

function ENT:AttemptClaim()
	net.Start("BaseCore")
		net.WriteUInt(BaseWars.Bases.Actions.Claim, BaseWars.Bases.Actions.SZ)
		net.WriteEntity(self)
	net.SendToServer()
end

function ENT:AttemptUnclaim()
	net.Start("BaseCore")
		net.WriteUInt(BaseWars.Bases.Actions.Unclaim, BaseWars.Bases.Actions.SZ)
		net.WriteEntity(self)
	net.SendToServer()
end

function ENT:OpenBaseView()
	BaseWars.Bases.BaseView.Activate(self)
end

hook.Add("NotifyShouldTransmit", "BaseCoreHalo", function(e, add)
	if not add then return end
	if not BaseWars.Bases.IsCore(e) then return end

	local ENT = scripted_ents.GetStored("bw_basecore").t
	local base = ENT.GetBase(e) -- fucking gmod is insane
	if not base then print(e, myBaseID, "didn't find base with that ID when entered PVS?") return end

	base:SetBaseCore(e)
end)


hook.Add("PreDrawHalos", "BaseCoreHalo", function()
	local lp = LocalPlayer()
	local base = lp:BW_GetBase()
	if not base then return end
	if lp:GetBase() == base then return end

	local core = base:GetBaseCore()
	if not core or not core:IsValid() then return end

	local dist = lp:GetPos():Distance(core:GetPos())
	local fr = math.max(math.min( (dist - 96) / 96, (768 - dist) / 512, 1 ), 0)

	if fr > 0 then
		local h,s,v = colObeyZ:ToHSV()

		core.Colors[2]:SetHSV(h, s * fr, v * fr)
		halo.Add(core.HaloTable, core.Colors[2], fr * 3, fr * 3, 3, true, false)
	end

	local blur = math.min(2, fr * 18)

	if blur > 0 then
		local h,s,v = colThroughWalls:ToHSV()
		core.Colors[1]:SetHSV( h, s, v * (blur / 2) )
		halo.Add(core.HaloTable, core.Colors[1], blur, blur, 1, true, true)
	end

end)