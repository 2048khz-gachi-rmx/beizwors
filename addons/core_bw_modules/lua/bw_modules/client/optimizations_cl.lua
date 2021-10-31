local st = Settings.Create("halo_enable", "bool")
	:SetDefaultValue(true)
	:SetCategory("Performance")
	:SetName("Enable halos (tanks FPS!)")

st = Settings.Create("bshadows_enable", "bool")
	:SetDefaultValue(true)
	:SetCategory("Performance")
	:SetName("Enable dynamic GUI shadows (tanks FPS!)")