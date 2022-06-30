AddCSLuaFile()

ENT.Base = "bw_base_upgradable"
ENT.Type = "anim"
ENT.PrintName = "Template GT Entity"

ENT.Model = "models/Gibs/HGIBS.mdl" -- forgor
ENT.Skin = 0

ENT.CanTakeDamage = true
ENT.NoHUD = false

function ENT:DerivedDataTables()
	self:NetworkVar("Bool", 2, "Working")
	self:TimeDTs()
end

function ENT:TimeDTs()
	self:NetworkVar("Float", 2, "NW_TimeStart")
	self:NetworkVar("Float", 3, "NW_TimeEnd")
	self:NetworkVar("Float", 4, "NW_ProgHalt")
end

function ENT:SetTimeStart(t, ...) self:SetNW_TimeStart(t) end
function ENT:SetTimeEnd(t, ...) self:SetNW_TimeEnd(t) end
function ENT:SetProgHalt(t, ...) self:SetNW_ProgHalt(t) end

function ENT:GetTimeStart(...) return self:GetNW_TimeStart() end
function ENT:GetTimeEnd(...) return self:GetNW_TimeEnd() end
function ENT:GetProgHalt(...) return self:GetNW_ProgHalt() end

function ENT:GetTime(...)
	-- must return start/end time
	return self:GetTimeStart(...), self:GetTimeEnd(...)
end

function ENT:SetTime(st, et, ...)
	if st then self:SetTimeStart(st, ...) end
	if et then self:SetTimeEnd(et, ...) end

	self:StateChanged()
end

function ENT:GetFrac(...)
	-- returns num, bool (% done, is_working)
	if self:GetProgHalt(...) ~= 0 then
		-- unpowered: startTime becomes % at which progress stopped
		return self:GetProgHalt(...), false
	end

	local st, en = self:GetTime(...)

	if st == 0 or en == 0 then return 0, false end

	local ct = CurTime()
	return math.RemapClamp(ct, st, en, 0, 1), true
end

function ENT:ShouldHalt()
	return not self:IsPowered()
end

function ENT:StateChanged()

end