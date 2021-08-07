if not LibItUp.Emitter then include('emitter.lua') end

local cmdPrefix = "lbu_"

Binds = Binds or {}

Binds.Data = Binds.Data or {}
Binds.Objects = Binds.Objects or {} -- [id] = bindObject
Binds.Keys = Binds.Keys or muldim:new()	-- [KEY_*][bind_ID] = bindObject
Binds.Concommands = Binds.Concommands or {}

local fileName = __LibName .. "_binds.txt"

local comment = [[
Don't touch this unless you're confident you won't mess it up.

You may want to use this page: https://wiki.facepunch.com/gmod/Enums/KEY
]]

local function writeData()
	local t = {}

	for line, num in eachNewline(comment) do
		if select(2, line:gsub("%w", "")) > 0 then
			line = "## " .. line
		end

		t[num] = line
	end

	t[#t + 1] = "\n\n"

	local dat = util.TableToJSON(Binds.Data, true)
	t[#t + 1] = dat

	file.Write(fileName, table.concat(t, "\n"))
end

local function readData()
	local dat = file.Read(fileName, "DATA")

	if not dat then
		writeData()
		return
	end

	local json = {}

	for line, num in eachNewline(dat) do
		if line:match("^##") then continue end
		json[#json + 1] = line
	end

	local bindData = util.JSONToTable(table.concat(json))
end

Binds.WriteData = writeData
Binds.ReadData = readData

BINDS_TOGGLE = "TOGGLE"
BINDS_HOLD = "HOLD"

Binds.BindData = Binds.BindData or Object:callable()
local bindData = Binds.BindData

bindData[1] = KEY_NONE
bindData[2] = BINDS_TOGGLE

local key_whitelist = {
	Key = 1,
	Method = 2
}

bindData.__index = function(self, k)
	if isnumber(k) then return bindData[k] end

	k = key_whitelist[k] or -1
	return self[k] or bindData[k]
end

bindData.__newindex = function(self, k, v)
	if not isnumber(k) then
		if not key_whitelist[k] then errorf("%s is not a whitelisted non-number index.", k) return end
		rawset(self, key_whitelist[k], v)
		return
	end

	rawset(self, k, v)
end

function bindData:Initialize(k, m)
	self[1] = k
	self[2] = m
end

local function cleanID(t, id)
	for i=#t, 1, -1 do
		if t[i].ID == id then
			table.remove(t, i)
		end
	end
end

LibItUp.Bind = LibItUp.Bind or LibItUp.Emitter:callable()
Bind = LibItUp.Bind

function Bind:Initialize(id)

	self.ID = id

	-- if an existing object for this ID already exists, just give that
	if Binds.Objects[id] then return Binds.Objects[id] end 
	Binds.Objects[id] = self

	-- if we have data for that bindID (preferred key/method), set those automatically
	if Binds.Data[id] then
		local dat = Binds.Data[id]
		self :SetKey(dat.Key)
			:SetMethod(dat.Method)
		return
	end

	-- otherwise, create new data
	Binds.Data[id] = bindData:new()
end

function Bind:GetData()
	return Binds.Data[self.ID]
end

-- exclusive means that bind and ONLY that bind will proc for this key
-- there can't be multiple exclusive binds on a key

-- there theoretically can be multiple binds and an exclusive bind,
-- but they just won't run

function Bind:GetExclusive()
	return self.Exclusive
end

function Bind:SetExclusive(b) --, prevent_default)	-- gmod sucks, cant prevent default lol
	if b == nil then b = true end

	if b and self.Key then
		for k,v in ipairs(Binds.Keys[self.Key]) do
			if v.Exclusive then
				return false, "There can't be multiple exclusive keys! (The other is " .. v.ID .. ")"
			end
		end
	end

	self.Exclusive = b
	--self.ExclusivePreventDefault = prevent_default
end


ChainAccessor(Bind, "Exclusive", "Exclusive")

function Bind:SetKey(k)
	local prev = self.Key
	if prev == k then return self end --bruh

	self.Key = k

	if Binds.Keys[prev] then
		cleanID(Binds.Keys[prev], self.ID)
	end

	if Binds.Keys[k] then
		cleanID(Binds.Keys[k], self.ID)

		if self.Exclusive then
			for k,v in ipairs(Binds.Keys[self.Key]) do
				if v.Exclusive then
					return false, "There can't be multiple exclusive keys! (The other is " .. v.ID .. ")"
				end
			end
		end

	end

	Binds.Keys:Insert(self, k)

	self:GetData().Key = k

	self:Emit("KeyChanged", prev, k)
	return self
end

function Bind:SetMethod(m)
	local prev = self.Method
	self.Method = m

	self:GetData().Method = m

	self:Emit("MethodChanged", prev, m)
	return self
end

function Bind:SetDefaultMethod(m)
	if not self.Method then
		self:SetMethod(m)
	end

	return self
end

function Bind:CreateConcommand(name)
	name = name or self.ID
	Binds.Concommands[name] = self
end

Bind:AliasMethod(Bind.CreateConcommand, "CreateConcommands")

function Bind:SetDefaultKey(k)
	if not self.Key then
		return self:SetKey(k)
	end

	return self
end

if CLIENT then

	-- only works on holdable binds
	function Bind:SetHeld(b)
		local ac = self:GetActive()
		self.__KeepHeld = b

		if b then
			if ac then return end
			-- if we weren't active before, activate now
			self:_Fire(true, LocalPlayer())
		else
			-- if we were active before only because of the Held state,
			-- we disable ourselves ( otherwise we leave it to the user )
			if self:GetButtonState() == false and self:GetActive() then
				self:_Fire(false, LocalPlayer())
			end
		end
	end

end

function Bind:GetHeld()
	return not not self.__KeepHeld
end

ChainAccessor(Bind, "__State", "Active")			-- the "custom" button state; can be influenced by addons (eg Bind:SetHeld(true))
ChainAccessor(Bind, "__BtnState", "ButtonState") 	-- the REAL button state, the player's input representing this bind currently

function Bind:_Fire(down, ply)

	if self.Method == BINDS_HOLD then
		if down and self:GetActive() then return end 	-- you can't re-activate a holdable bind
		if not down and self:GetHeld() then return end 	-- if the bind is forced to be held, don't deactivate it

		self:SetActive(down)
		self:Emit(down and "Activate" or "Deactivate", ply)
		
	elseif self.Method == BINDS_TOGGLE and down then
		local newState = not self.__State
		self:SetActive(newState)
		self:Emit(newState and "Activate" or "Deactivate", ply)
	end

end

hook.Add("PlayerButtonDown", __LibName .. "_BindsDown", function(ply, btn)
	if not Binds.Keys[btn] then return end
	if not IsFirstTimePredicted() then return end

	local binds = Binds.Keys[btn]

	for _, bind in ipairs(binds) do
		if not bind.Exclusive then continue end
		if bind:Emit("ShouldActivate") == false then continue end

		bind:SetButtonState(true)
		bind:Emit("ButtonChanged", true)

		bind:_Fire(true, ply)
		return -- exclusive bind
	end


	for _, bind in ipairs(binds) do
		if bind:Emit("ShouldActivate") == false then continue end

		bind:SetButtonState(true)
		bind:Emit("ButtonChanged", true)

		bind:_Fire(true, ply)
	end

end)

hook.Add("PlayerButtonUp", __LibName .. "_BindsUp", function(ply, btn)
	if not Binds.Keys[btn] then return end
	if not IsFirstTimePredicted() then return end

	local binds = Binds.Keys[btn]

	for _, bind in ipairs(binds) do
		if not bind.Exclusive then continue end
		if bind:Emit("ShouldDeactivate") == false then continue end

		bind:SetButtonState(false)
		bind:Emit("ButtonChanged", false)

		bind:_Fire(false, ply)
		return -- exclusive bind
	end


	for _, bind in ipairs(binds) do
		if bind:Emit("ShouldDeactivate") == false then continue end

		bind:SetButtonState(false)
		bind:Emit("ButtonChanged", false)

		bind:_Fire(false, ply)
	end
end)

--[[
	Concommands
]]

local function autoCompleter(method)
	return function(cmd, args)
		args = args:Trim()

		local ret = {}

		for k,v in pairs(Binds.Concommands) do
			if v.Method ~= method then continue end
			if args ~= "" then
			 	local lw = v.ID:lower()
			 	local exact = lw:sub(1, #args) == args
			 	local fuzzy = lw:find(args, 1, true) and #lw < #args * 3
			 	if not exact and not fuzzy then continue end
			 end
			ret[#ret + 1] = cmd .. " " .. v.ID
		end

		return ret
	end
end


concommand.Add(cmdPrefix .. "bindToggle", function(ply, _, _, str)
	if not Binds.Concommands[str] then
		print("unknown bind: " .. (str or ""))
		return
	end

	local bnd = Binds.Concommands[str]

	if bnd.Method ~= BINDS_TOGGLE then
		printf("bind `%s` is not toggleable", str)
		return
	end

	bnd:_Fire(true, ply)
end, autoCompleter(BINDS_TOGGLE))

local function checkBindHoldable(str)
	if not Binds.Concommands[str] then
		print("unknown bind: " .. (str or ""))
		return
	end

	local bnd = Binds.Concommands[str]

	if bnd.Method ~= BINDS_HOLD then
		printf("bind `%s` is not holdable", str)
		return
	end

	return bnd
end

local function onHold(ply, _, _, str)
	local bnd = checkBindHoldable(str)
	if not bnd then return end

	bnd:_Fire(true, ply)
end

local function onUnhold(ply, _, _, str)
	local bnd = checkBindHoldable(str)
	if not bnd then return end
	
	bnd:_Fire(false, ply)
end


concommand.Add("+" .. cmdPrefix .. "bind", onHold, autoCompleter(BINDS_HOLD))
concommand.Add("-" .. cmdPrefix .. "bind", onUnhold, autoCompleter(BINDS_HOLD))