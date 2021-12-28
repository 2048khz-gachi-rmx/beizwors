Offhand = Offhand or {}

Offhand.Binds = Offhand.Binds or {}
Offhand.CurrentActions = Offhand.CurrentActions or {}
Offhand.InactiveColor = Colors.LightGray:Copy()

-- defaults
local keys = {
	KEY_G, KEY_H, KEY_J,
	KEY_B, KEY_N
}

local function fillBind(bind)
	bind:On("Activate", "ShowChoices", function(self)
		self:Timer("ShowChoices", 0.2, 1, function()
			Offhand.ShowChoices(self)
			self.ActionsShown = true
		end)
	end)

	bind:On("Deactivate", "ShowChoices", function(self)
		--local do_action = not self.Wheel

		--if do_action then

		self:RemoveTimer("ShowChoices")

		if self.Wheel then
			Offhand.HideChoices(self)
			return
		end

		local action = Offhand.GetBindAction(self)
		if not action then return end

		action = Offhand.Actions[action]

		if not action then
			-- errorNHf("Offhand action not found! %q", action)
			return
		elseif isfunction(action.Use) then
			action.Use(LocalPlayer())
		end

		--[[else
			Offhand.HideChoices(self)
		end]]
	end)
end

function Offhand.GetAction(name)
	return Offhand.Actions[name]
end

function Offhand.CreateBinds(n)
	for i=1, n or 1 do

		local bind = ChainValid(Offhand.Binds[i]) or
			Bind("offhand_" .. i)
				:SetDefaultKey(keys[i] or nil)
				:SetDefaultMethod(BINDS_HOLD)
				:CreateConcommand()

		bind.ActionNum = i
		Offhand.Binds[i] = bind

		--local key = cookie.GetNumber("offhand_key_" .. i)
		local act = cookie.GetString("offhand_action_" .. i)

		Offhand.CurrentActions[i] = act

		--[[if Bind.IsValidKey(key) then
			bind:SetKey(key)
		else
			cookie.Set("offhand_key_" .. i, keys[i])
		end]]

		fillBind(bind)
	end
end

if CLIENT then
	Offhand.CreateBinds(3)
end

Offhand.Actions = Offhand.Actions or {}
function Offhand.Register(name, dat)
	if not istable(dat) then
		errorNHf("data table required for offhand registering")
		return
	end

	Offhand.Actions[name] = dat
end

function Offhand.GetBindAction(bind)
	local id = bind.ActionNum
	return Offhand.CurrentActions[id]
end

function Offhand.SetBindAction(bind, act)
	local id = bind.ActionNum
	Offhand.CurrentActions[id] = act
	cookie.Set("offhand_action_" .. id, act)
end

if CLIENT then
	local curWheel
	local curBind

	function Offhand.ShowChoices(bind)
		if bind.Wheel then Offhand.HideChoices(bind) end

		local wh = LibItUp.InteractWheel:new()
		bind.Wheel = wh
		curWheel = wh
		curBind = bind -- hacky solution but whatever
		hook.Run("Offhand_GenerateSelection", bind, wh)

		wh:Show()

		if bind._SelectChoice then
			wh:PointOnOption(bind._SelectChoice)
			bind._SelectChoice = nil
		end

		wh:On("Hide", "HideChoice", function()
			bind:Deactivate()
			bind.Wheel = nil
		end)

		wh:On("RightClick", "Hide", function()
			bind:Deactivate()
		end)

		function wh:OnSelect(opt)
			Offhand.SetBindAction(bind, opt.ActionName)
		end
	end

	function Offhand.HideChoices(bind)
		if not bind.Wheel then return end
		bind.Wheel:Hide()
		bind.Wheel = nil
	end

	function Offhand.AddChoice(id, ...)
		local ch = curWheel:AddOption(...)
		ch.ActionName = id

		local action = Offhand.GetBindAction(curBind)
		if id and id == action then
			curBind._SelectChoice = ch
		end

		return ch
	end

	function Offhand.RequestAction(act, ns)
		-- nooooo you cant just network a string instead of
		-- making a 200 lines encoder for stringName <-> numberID

		net.Start("OffhandAction")
			local pr = net.StartPromise()
			net.WriteString(act)
			if IsNetStack(ns) then
				ns:Write()
			end
		net.SendToServer()

		return pr
	end

	net.Receive("OffhandAction", function()
		net.ReadPromise()
	end)
else
	util.AddNetworkString("OffhandAction")

	net.Receive("OffhandAction", function(len, ply)

		local pr = net.ReplyPromise(ply)

		local name = net.ReadString()
		if not name then pr:ReplySend("OffhandAction", false) return false end

		local act = Offhand.Actions[name]
		if not act then pr:ReplySend("OffhandAction", false) return false end

		if isfunction(act.Use) then
			local out = act.Use(ply)

			if out ~= nil then
				print("promise reply:", out)
				pr:ReplySend("OffhandAction", out)
			end
		end
	end)
end