GSLT_Set = GSLT_Set

local function addGSLT()
	local gslt = Settings.GetStored("GSLT")
	if not gslt then
		for i=1, 10 do
			print("!!! GSLT setting missing !!!")
		end

		return
	end

	RunConsoleCommand("sv_setsteamaccount", Settings.GetStored("GSLT", "74E5FAD9CD89DC9EB6072C344D75185E"))
end

function fuckyou()
	if jit.os == "Linux" then
		RunConsoleCommand("hostname",
			Settings.GetStored("Hostname", "lodestar - alpha | titleless...?")
			)
	end

	if not GSLT_Set then
		addGSLT()
		GSLT_Set = true
	end

	--RunConsoleCommand("sv_downloadurl", "https://vaati.net/Gachi/garrysmod")
	--RunConsoleCommand("sv_downloadurl", "http://9840cbe192b59391.daemon.panel.gg/25017be5/")

	if Settings.GetStored("LoadingURL", false) then
		RunConsoleCommand("sv_loadingurl", Settings.GetStored("LoadingURL",
			"https://ldstar.net/loading?sid=%s"))
	end
end

timer.Create("fuckyou", 30, 0, fuckyou)
hook.Add("InitPostEntity", "fuckoff_crydent", fuckyou)
fuckyou()

if ArcCW then
	ArcCW.DoorBustEnabled = 1
	ArcCW.DoorBustTime = 180
end