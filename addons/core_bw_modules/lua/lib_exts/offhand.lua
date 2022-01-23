Offhand = Offhand or {}

Offhand.Binds = Offhand.Binds or {}
Offhand.CurrentActions = Offhand.CurrentActions or {}
Offhand.InactiveColor = Colors.LightGray:Copy()

-- defaults
local keys = {
	KEY_G, KEY_H, KEY_J,
	KEY_B, KEY_N
}

local fillBind
local wheelTimer = 0.2

if CLIENT then
	function fillBind(bind)
		function bind:DoActivate(action)
			local first = IsFirstTimePredicted()

			if not action then
				-- errorNHf("Offhand action not found! %q", action)
				return
			else
				if not first and not action.CanPredict then return end

				Offhand.TryActivate(action, LocalPlayer())
			end
		end


		bind:On("Activate", "ShowChoices", function(self)
			local first = IsFirstTimePredicted()

			if not first then
				local action = Offhand.GetBindAction(self)
				if not action then return end

				action = Offhand.Actions[action]

				if action and action.ActivateOnPress then
					self:DoActivate(action)
				end

				return
			end

			self:Timer("ShowChoices", wheelTimer, 1, function()
				Offhand.ShowChoices(self)
				self.ActionsShown = true
			end)

			local action = Offhand.GetBindAction(self)
			if not action then return end

			action = Offhand.Actions[action]

			if action and action.ActivateOnPress then
				self:DoActivate(action)
			end
		end)


		-- uglie but works, ig
		local kms = {}

		function bind:fucking_kms()
			table.Empty(kms)
		end

		bind:On("Deactivate", "ShowChoices", function(self)
			local first = IsFirstTimePredicted()

			if first then
				self:RemoveTimer("ShowChoices")
			end

			if kms[CurTime()] then return end

			if self.Wheel then
				if first then
					Offhand.HideChoices(self)
				end

				-- kill any attempts to deactivate for this pred frame
				kms[CurTime()] = true
				self:Timer("aaaaaaaaaa", 5, 1, bind.fucking_kms)
				return
			end

			local action = Offhand.GetBindAction(self)
			if not action then return end

			action = Offhand.Actions[action]
			if action and not action.ActivateOnPress then
				self:DoActivate(action)
			end
		end)
	end
else
	function fillBind(bind)
		bind.plys = {}

		function bind:DoActivate(ply, action)
			if not action then
				-- errorNHf("Offhand action not found! %q", action)
				return
			else
				if not action.Synced then return end

				Offhand.TryActivate(action, ply)
			end
		end

		bind:On("Activate", "ShowChoices", function(self, ply)
			bind.plys[ply] = CurTime()

			local action = Offhand.GetBindAction(self, ply)
			if not action then return end

			action = Offhand.Actions[action]

			if action and action.ActivateOnPress then
				self:DoActivate(ply, action)
			end
		end)

		bind:On("Deactivate", "DoOffhand", function(self, ply)
			if CurTime() - bind.plys[ply] > wheelTimer then
				return
			end

			local action = Offhand.GetBindAction(self, ply)
			if not action then return end

			action = Offhand.Actions[action]

			if action and not action.ActivateOnPress then
				self:DoActivate(ply, action)
			end

			--[[else
				Offhand.HideChoices(self)
			end]]
		end)
	end
end

function Offhand.GetAction(name)
	return Offhand.Actions[name]
end

function Offhand.CreateBinds(n)
	for i=1, n or 1 do
		local bind = ChainValid(Offhand.Binds[i]) or Bind("offhand_" .. i)

		bind:SetDefaultKey(keys[i] or nil)
			:SetDefaultMethod(BINDS_HOLD)
			:SetCanPredict(true)
			:SetSynced(true)
			:CreateConcommand()

		bind.ActionNum = i
		Offhand.Binds[i] = bind

		local act = cookie.GetString("offhand_action_" .. i)

		Offhand.SetBindAction(bind, act)

		fillBind(bind)
	end
end

Offhand.Actions = Offhand.Actions or {}
function Offhand.Register(name, dat)
	if not istable(dat) then
		errorNHf("data table required for offhand registering")
		return
	end

	Offhand.Actions[name] = dat
	dat.Name = name
end

function Offhand.GetBindAction(bind, ply)
	local id = bind.ActionNum
	if SERVER then return ply._offhandBinds and ply._offhandBinds[id] end
	return Offhand.CurrentActions[id]
end

function Offhand.SetBindAction(bind, act)
	local id = bind.ActionNum
	Offhand.CurrentActions[id] = act
	cookie.Set("offhand_action_" .. id, act)

	if CLIENT then
		OnFullyLoaded(function()
			net.Start("offhand_bind")
				net.WriteUInt(id, 4)
				net.WriteString(act)
			net.SendToServer()
		end)
	end
end

function Offhand.TryActivate(name, ply)
	local action = istable(name) and name or Offhand.Actions[name]
	if not action then return false end

	action._cds = action._cds or {}

	if Offhand.GetCooldown(name, ply) > 0 then
		return false, false
	end

	local ret

	if isfunction(action.Use) then
		ret = action.Use(ply)
		ret = ret == nil or ret
	else
		ret = true
	end

	if ret then
		local cd = isnumber(action.Cooldown) and action.Cooldown
			or eval(action.Cooldown, ply, ret) or 0

		Offhand.SetCooldown(name, ply, CurTime() + cd)
	end

	return ret, true
end

function Offhand.SetCooldown(name, ply, till)
	if istable(name) then
		if name.CanPredict then
			ply:SetNW2Float("offhand_cd_" .. name.Name, till)
		else
			name._cds = name._cds or {}
			name._cds[ply] = till
		end
	else
		local action = Offhand.Actions[name]
		if not action then errorf("no action: %s", name) return false end

		if action.CanPredict then
			ply:SetNW2Float("offhand_cd_" .. name, till)
		else
			action._cds = action._cds or {}
			action._cds[ply] = till
		end
	end
end

function Offhand.GetCooldown(name, ply)
	if CLIENT then ply = CachedLocalPlayer() end

	if istable(name) then
		local till = name.CanPredict and
			ply:GetNW2Float("offhand_cd_" .. name.Name, 0) or
			name._cds[ply] or 0

		return math.max(0, till - CurTime()), till
	else
		local action = Offhand.Actions[name]
		if not action then errorf("no action: %s", name) return false end

		local till = action.CanPredict and
			ply:GetNW2Float("offhand_cd_" .. name, 0) or
			action._cds[ply] or 0

		return math.max(0, till - CurTime()), till
	end
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
		-- making a 200 lines [de]serializer for stringName <-> numberID

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
	util.AddNetworkString("offhand_bind")

	net.Receive("OffhandAction", function(len, ply)

		local pr = net.ReplyPromise(ply)

		local name = net.ReadString()
		if not name then pr:ReplySend("OffhandAction", false) return false end

		local ok = Offhand.TryActivate(name, ply)
		if not ok then pr:ReplySend("OffhandAction", false) return false end
	end)

	net.Receive("offhand_bind", function(len, ply)
		ply._offhandBinds = ply._offhandBinds or {}
		ply._offhandBinds[net.ReadUInt(4)] = net.ReadString()
	end)
end

-- now initialize
Offhand.CreateBinds(3)