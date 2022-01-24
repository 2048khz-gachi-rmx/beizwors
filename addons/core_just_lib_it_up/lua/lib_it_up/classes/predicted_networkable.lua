setfenv(0, _G)

if not Networkable then include("networkable.lua") end -- end me
-- do return end -- bad bad bad

--[[
	terms:
		Prediction Run - completely new runs of predicted hooks containing prediction frames (eg shooting with a weapon starts a Prediction Run)
		Prediction Frame - runs of multiple predicted actions for the same CurTime (eg PrimaryAttack getting called multiple times; each call is a Prediction Frame)

		Stream - kv's which are used in prediction frames; each prediction frame will modify vars into streams instead of baseline
		BaseLine - basically main stream, what we'll use outside of prediction (server also updates its' vars into baseline)
]]

local Stream = Object:callable()
function Stream:Initialize()
	self.Data = {}
	self.BaseLine = {}

	self.Copied = {}	--seq table of streams that copied this one's data
	self.CopiedData = {} -- [k] = stream from which we copied the key
end

function Stream:Set(k, v, backupBase)
	--clprint("Set", self.Time, k, v)
	self.Data[k] = v
	self.CopiedData[k] = nil
	if backupBase then
		for bk, bv in pairs(backupBase.BaseLine) do
			self.BaseLine[bk] = bv
		end
	end
end

PredNetworkable = PredNetworkable or Networkable:callable()
local nw = PredNetworkable

nw.__tostring = function(self) return "PredNW" end
Stream.__tostring = function(self) return string.format("PredNWStream @ %f (%p)", self.Time, self) end
local allNWs = _AllPredNWs or WeakTable("v")
_AllPredNWs = allNWs

local JITTER_THRESHOLD = 500 / 1000

if CLIENT then
	local valid = false

	timer.Create("PredNW_GC", 0.1, 0, function()
		if not valid and not LocalPlayer():IsValid() then return end -- gmod plx

		local rCT = CurTime() - math.max(0.07, LocalPlayer():Ping() / 100 + JITTER_THRESHOLD)
		--print((LocalPlayer():Ping() / 500 + JITTER_THRESHOLD))

		for k,v in pairs(allNWs) do
			for ct, _ in pairs(v.Streams) do
				if rCT > ct  then
					--clprint("Cleaned up stream", ct, rCT)
					v.Streams[ct] = nil -- you won't be missed
				end
			end

			for ct, uct in pairs(v.ActiveRuns) do
				if rCT > ct then
					--clprint("Cleaned up active run", ct, rCT)
					v.ActiveRuns[ct] = nil
				end
			end
		end

		JITTER_THRESHOLD = LocalPlayer():Ping() / 1000 / 2 + 0.5
	end)
end

nw:On("Invalidated", "CleanPredNW", function(self)
	for k,v in pairs(_AllPredNWs) do
		if v == self then
			table.remove(_AllPredNWs, k)
			break
		end
	end
end)
nw.Unreliable = true
function nw:Initialize(id)

	--[[
		[unpred_ctime] = {
			Key = Val, ...
		},
	]]

	self.ActiveRuns = {} -- [curtime] = unpredCT (when the first predicted frame happened)
	self.BaseLine = {}

	self.Streams = muldim:new()

	if id then self:SetNetworkableID(id, true) end
	self.LastPredFrame = 0 --UnPredictedCurTime
	self.BaseLineWhen = 0
	self.BaseLineServer = 0
	-- self.MaxCTStream = math.huge  -- can't; we know UCT will never be less than the previous value, but CT can be due to winding forward
	self.MaxUCTStream = math.huge

	self:Alias("__ct", 255, "Float")
	allNWs[#allNWs + 1] = self
end

function nw:CreateStream(time)
	local st = Stream()
	st.Time = time
	self.Streams[time] = st
	--local print = BlankFunc
	--clprint("Created", st, CurTime(), self.ActiveRuns[CurTime()] and self.Streams[self.ActiveRuns[CurTime()]])
	local str, strWhen = self:GetClosestPredRun(time)

	if str then
		str.Copied[#str.Copied + 1] = st
		--print("	Copying data from stream @", strWhen)
		--PrintTable(str.Data)
	end

	if str then
		for k,v in pairs(str.BaseLine) do
			--print("	Set #2", k, v)
			st:Set(k, v)
			str.CopiedData[k] = str
		end
	end

	self.MaxUCTStream = time
	self.MaxCTStream = math.max(self.MaxCTStream or 0, CurTime())
	return st
end

function nw:GetStream(time)
	return self.Streams[time] or self:CreateStream(time)
end

local fug = bench("Fugg", 6000)
local lf = 0

function nw:GetClosestPredRun(ct, key, cmd, p) -- behind `ct`
	local print = print
	if not p or SERVER then print = BlankFunc end

	local mCT = self.MaxCTStream

	if mCT and ct > mCT then -- maybe we can return a cached stream?
		local uCT = self.ActiveRuns[mCT]
		local str = self.Streams[uCT]

		if str and str.Data[key] ~= nil then
			return str, uCT
		end
	end

	if not cmd then cmd = false end

	local mx = 0

	for k,v in pairs(self.ActiveRuns) do

		if k < ct then
			local str = self.Streams[v]
			if not str then self.ActiveRuns[k] = nil continue end

			if str.Data[key] ~= nil and str.Cmd ~= cmd then
				mx = math.max(v, mx)
			elseif str.Cmd == cmd and key == 1 then
				--clprint("can't use due to same cmd", str)
			elseif str.Data[key] == nil and key == 1 then
				--clprint("can't use due to missing key", str, key)
			end

		end
	end

	return self.Streams[mx], mx
end

function nw:GetClosestPredRunUnpred(uct, key, lim, p)
	local print = print
	if not p or SERVER and false then print = BlankFunc end

	local mUCT = self.MaxUCTStream

	if uct > mUCT then -- maybe we can return a cached stream?
		local str = self.Streams[mUCT]
		if str and str.Data[key] ~= nil then return str, mUCT end
	end

	local mx = 0
	local str = nil

	for k, v in pairs(self.Streams) do
		--print(k, v, uct)

		if k < uct then
			if not key or v.Data[key] ~= nil then
				mx = math.max(k, mx)
				if mx == k then str = v end
			else
				--print("no key or no data for key", v, v.Data[key])
			end
		end
	end
	--print("found:", mx)
	--if lim and mx < lim then return false end
	return str, mx
end

function nw:Set(k, v)
	--if self.__Aliases[k] ~= nil then k = self.__Aliases[k] end

	if SERVER then
		if self.Networked[k] == v then return self end

		local a = self.__parent.Set(self, k, v)
		self.__parent.Set(self, "__ct", CurTime())

		timer.Create("NWNetwork" .. tostring(self.NetworkableID), 0, 1, function()
			if self:IsValid() then
				self.__parent.Network(self)
			end
		end)

		return a
	end

	local when = CurTime()					-- shared between multiple pred frames of a single run
	local streamWhen = UnPredictedCurTime() -- shared between multiple runs in a single pred frame

	local pred = force_pred or streamWhen ~= when or not IsFirstTimePredicted()
	local first_pred = IsFirstTimePredicted()

	if not pred then
		--print("!!set baseline from unpred", CurTime(), k, v)
		self.BaseLine[k] = v
		self.BaseLineWhen = when
	else
		--print("!!set stream from pred", CurTime(), streamWhen)
		--clprint("Set pred", k, v, streamWhen)
		local stream = self:GetStream(streamWhen)
		stream.LastPredRun = when
		stream:Set(k, v, first_pred and self)

		if first_pred then
			--clprint("	Setting on first pred:", stream.Time, k, v)
		end

		local ply = GetPredictionPlayer()
		local cmd = ply ~= NULL and ply:GetCurrentCommand():CommandNumber()
		stream.Cmd = cmd
		--clprint("Post-create: now", k, stream.Data[k])

		for k,v in ipairs(stream.Copied) do
			if v.CopiedData[k] == stream then
				v:Set(k, v)
			end
		end

		if first_pred then
			--print("!!!!!!!first pred", when, streamWhen)
			self.ActiveRuns[when] = streamWhen
		end
	end

end

local print = print
local acPrint = print

function nw:Get(k, p, no_pred)
	if SERVER then
		return self.__parent.Get(self, k)
	end

	--if self.__Aliases[k] ~= nil then k = self.__Aliases[k] end

	if p then print = acPrint else print = BlankFunc end

	local when = CurTime()
	local streamWhen = UnPredictedCurTime()

	local pred = not no_pred and (streamWhen ~= when or not IsFirstTimePredicted())
	if no_pred == false then pred = true end

	if pred then -- we're in prediction; either grab current prediction frame's var, first prediction frame's var in a pred run before this one or baseline
		print("pred", streamWhen)
		local stream = self.Streams[streamWhen]
		local ply = GetPredictionPlayer()
		local cmd = ply ~= NULL and ply:GetCurrentCommand():CommandNumber()
		print(ply, cmd, stream)
		if stream and (stream.Data[k] == nil or (stream.Cmd and stream.Cmd ~= cmd)) then
			print("stream cmd matches; bail")
			stream = nil
		end

		local streamFrom
		if not stream then
			print("finding le stream", when)
			stream, streamFrom = self:GetClosestPredRun(when, k, cmd, true)
		end

		print(stream, streamFrom, stream and stream.Time, self.BaseLineWhen)

		if streamFrom and self.ActiveRuns[self.BaseLineWhen] and streamFrom < self.ActiveRuns[self.BaseLineWhen] then
			print("using baseline since its more recent", self.BaseLineWhen, streamWhen, streamFrom, when)
			return self.BaseLine[k], self.BaseLineWhen
		end

		local var = stream and stream.Data[k]
		print("using stream", var, stream and stream.Time, streamWhen, self.BaseLineWhen, when)
					-- the pred run is so old that we already lost the baseline data since it was overwritten by new data from the server;
					-- time ta pull the old baseline from the stream!!!
		print(CurTime(), self.BaseLineWhen)
		if stream and (--[[stream.Time < self.BaseLineServer or ]]var == nil) then
			print("using stream baseline..?", stream.BaseLine[k])
			var = stream.BaseLine[k]
		end

		if var ~= nil then
			return var, streamFrom or streamWhen
		end -- if the current prediction frame has that var set, return it

		print("returned to baseline")
		return self.BaseLine[k], self.BaseLineWhen -- otherwise, return to baseline
	else
		print("unpred")
		local stream = self.Streams[streamWhen]
		local closestTime
		if stream then print("using current uct stream", stream.Data[k]) end
		if not stream or not stream.Data[k] then
			stream, closestTime = self:GetClosestPredRunUnpred(streamWhen, k, self.BaseLineWhen, p)
		end

		local blVar = self.BaseLine[k]

		if closestTime and self.ActiveRuns[self.BaseLineWhen] and closestTime < self.ActiveRuns[self.BaseLineWhen] and blVar then -- use baseline if it's more recent than whatever stream we have
			print("using NW baseine for var")
			return blVar, self.BaseLineWhen
		end

		local ret
		if stream then
			ret = stream.Data[k]
			print("using stream", ret, stream, closestTime, streamWhen, self.BaseLineWhen, when)
			if ret == nil then ret = stream.BaseLine[k] print("using stream baseline..?", stream.BaseLine[k]) end
		end
		if ret == nil then ret = blVar print("falling back to NW baseline") end

		return ret, closestTime or streamWhen
	end
end



function nw:GetPredicted(k, p)
	return self:Get(k, p, false)
end

function nw:GetUnpredicted(k, p)
	return self:Get(k, p, true)
end

if CLIENT then
	local print = acPrint

	nw:On("NetworkedChanged", "MergeIntoBaseline", function(self, changes)

		if self.BaseLineServer and (not self.BaseLineWhen or self.BaseLineServer >= self.BaseLineWhen) then

			for k,v in pairs(changes) do
				self.BaseLine[k] = v[2]
				self:Emit("PredNetworkedVarChanged", k, v[1], v[2])
			end

			self.BaseLineWhen = self.BaseLineServer
			self.BaseLine.__ct = nil
			--self.BaseLineServer = nil
		end

	end)

	nw:On("NetworkedVarChanged", "MergeIntoBaseline", function(self, key, old, new)
		if key == self.__Aliases["__ct"] then
			if self.BaseLineWhen < new then
				--self.BaseLineWhen = new
				self.BaseLineServer = new
			end
			self.Networked.__ct = nil
		end
	end)
end