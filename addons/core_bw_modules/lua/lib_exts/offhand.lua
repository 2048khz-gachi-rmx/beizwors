Offhand = Offhand or {}

Offhand.Bind = Offhand.Bind or Bind("offhand")
	:SetDefaultKey(KEY_G)
	:SetDefaultMethod(BINDS_HOLD)

Offhand.Bind:CreateConcommand()

Offhand.Actions = Offhand.Actions or {}
Offhand.CurrentAction = Offhand.CurrentAction or "Stim"

function Offhand.Register(name, func)
	Offhand.Actions[name] = func or true
end

local bind = Offhand.Bind

if CLIENT then
	bind:On("Activate", "ShowChoices", function(self)
		self:Timer("ShowChoices", 0.15, 1, function()
			Offhand.ShowChoices()
		end)
	end)

	bind:On("Deactivate", "ShowChoices", function(self)
		self:RemoveTimer("ShowChoices")

		local do_action = not Offhand.Wheel

		if do_action then
			if not Offhand.Actions[Offhand.CurrentAction] then
				errorNHf("Offhand action not found! %q", Offhand.CurrentAction)
				return
			elseif isfunction(Offhand.Actions[Offhand.CurrentAction]) then
				Offhand.Actions[Offhand.CurrentAction] ()
			end
		else
			Offhand.HideChoices()
		end
	end)

	function Offhand.ShowChoices()
		if Offhand.Wheel then return end

		local wh = LibItUp.InteractWheel:new()
		Offhand.Wheel = wh
		hook.Run("Offhand_GenerateActionSelection", wh)

		wh:Show()

		if Offhand._SelectChoice then
			wh:PointOnOption(Offhand._SelectChoice)
			Offhand._SelectChoice = nil
		end
	end

	function Offhand.HideChoices()
		if not Offhand.Wheel then return end
		Offhand.Wheel:Hide()
		Offhand.Wheel = nil
	end

	function Offhand.AddChoice(id, ...)
		local ch = Offhand.Wheel:AddOption(...)
		if id == Offhand.CurrentAction then
			Offhand._SelectChoice = ch
		end

		return ch
	end
end