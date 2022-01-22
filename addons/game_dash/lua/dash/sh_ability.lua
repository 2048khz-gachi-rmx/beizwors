--

function Dash.Can(ply)
	return true
end

Dash.OffhandTable = {
	Use = function(ply) Dash.Begin(ply) end,
	Paint = function(...) Dash.PaintAbility(...) end,
	CanPredict = true,
	Synced = true,
	ActivateOnPress = true
}

Offhand.Register("Dash", Dash.OffhandTable)

hook.Add("Offhand_GenerateSelection", "Dash", function(bind, wheel)
	if not Dash.Can(CachedLocalPlayer()) then return end

	Offhand.AddChoice("Dash",
		"Dash", "Briefly gain momentum in the direction you're looking.",
		Icon("https://i.imgur.com/mClnf6i.png", "ffw_64.png"):
			SetSize(64, 48))
end)