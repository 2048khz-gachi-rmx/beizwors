
local nx = NX
nx.Detections = nx.Detections or {}
nx.Detection = nx.Detection or Emitter:extend()

local dtc = nx.Detection
local idLim = 65535

ChainAccessor(dtc, "_Name", "Name")
ChainAccessor(dtc, "_ID", "ID")
ChainAccessor(dtc, "_CD", "CD")
ChainAccessor(dtc, "_CD", "CoolDown")
ChainAccessor(dtc, "_CD", "Cooldown")

dtc.IsDetection = true
dtc.DefaultCooldown = 3

Timerify(dtc)

function dtc:Initialize(name, numID)
	CheckArg(2, numID, "number")

	if numID > idLim then
		errorf("Detection ID (%d) > %d!", numID, idLim)
	end

	self:SetName(name)
	self:SetID(numID)
	self:SetCooldown(LibItUp.Cooldown:new(name, CurTime))

	nx.Detections[name] = self
	nx.Detections[numID] = self
end

function dtc:__tostring()
	return ("%s[%d]"):format(self:GetName(), self:GetID())
end

function NX.RegisterDetection(...) return dtc:Initialize(...) end

function NX.GetDetection(what)
	if IsDetection(what) then return what end
	return nx.Detections[what]
end

-- players that are actually loaded n shit
NX.PlayerList = NX.PlayerList or {}

function NX.ShouldIgnore(ply)
	return not NX.PlayerList[ply] or
		ply:IsTimingOut() or
		ply:IsBot()
end

hook.Add("PlayerFullyLoaded", "NX_Ready", function(ply)
	NX.PlayerList[ply] = true
end)

for k,v in ipairs(player.GetAll()) do
	if v:IsFullyLoaded() then
		NX.PlayerList[v] = true
	end
end

function dtc:Detect(ply, addData)
	local cd = self:GetCooldown()

	if not cd:Put(ply, 3) then
		self:Timer(("%p"):format(ply), 3, 1, function()
			self:Detect(ply, addData)
		end)
		return
	end

	local pin = GetPlayerInfoGuarantee(ply)

	NX.AddInfraction(ply, self:GetID(), addData)
	hook.NHRun("NX_Detection", pin, self, addData)
end

function IsDetection(what)
	return getmetatable(what) and getmetatable(what).IsDetection
end

local lg = Logger("Naloxol", Color(200, 40, 180))
hook.Add("NX_Detection", "Notify", function(pin, det, dat)

	local datStr = ""
	if istable(dat) then
		datStr = "\nExtra data: \n"
		local first = true
		for k,v in pairs(dat) do
			datStr =  datStr .. (not first and "\n" or "") ..
				("	%s: 	%s"):format(k, v)
			first = false
		end
	elseif dat then
		datStr = tostring(dat)
	end

	lg("%q [%s] was detected for: %s%s", pin:GetName(), pin:SteamID64(), det:GetName(),
		datStr)
end)