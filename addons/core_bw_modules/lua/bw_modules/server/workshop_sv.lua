local debuggingDownloads = false


local BWAddons = {
	"160250458", --wire
	"922947756", --synths

	game.GetMap() == "rp_downtown_tits_v2" and "1590239460" or -- tits
	game.GetMap():match("evocity") and "296828130", --bw evocity

	"546392647", --media players

	"897690679", -- particles - fa:s
	"284266415", -- scifi prop pack
	"1243825019", -- mil cases prop pack

	"2131057232", -- arccw base(d on what)
	"2131058270", -- arccw cs+
	"2175261690", -- arccw fa:s 1
	"2131161276", -- arccw m9k "extras"
	"2257255110", -- arccw GO
	"2393318131", -- arccw fa:s 2
	"2427171109", -- gso unlamifier

	"2409364730", -- gunsmith offensive extras

	"2155366756", -- vmanip

	-- cw2
	"427204862", -- raging bull
	"838920776", -- bullpups
	"591075724", -- mosin
	"1589205037", -- acr
	"349050451", -- cw2 base
	"358608166", -- cw2 unofficial
}





local subdirs = 0

local function indent(t)
	return string.rep("    ", t)
end

local function DownloadFolder(str, mask)
	local files, folders = file.Find(str .. (mask and "/" .. mask or "/*"), "MOD", "namedesc")

	local root = false

	if subdirs == 0 and debuggingDownloads then
		root = true
		MsgC(
			Color(150, 150, 230), "Adding root folder: ",
			Color(200, 200, 200), str, "\n")
		subdirs = subdirs + 1
	end

	for k,v in pairs(files) do

		if not string.find(v, "ztmp") then
			resource.AddSingleFile(str .. "/" .. v)
			if debuggingDownloads then
				MsgC(Color(160, 230, 80), indent(subdirs), "Added file: ",
					Color(220, 220, 220), str .. "/" .. v .. "\n")
			end
		end

	end

	if not table.IsEmpty(folders) then

		for k,v in pairs(folders) do

			if debuggingDownloads then
				MsgC("\n", indent(subdirs),
					Color(200, 250, 90),"Added folder: ",
					Color(220, 220, 220), str .. "/" .. v .. "\n")

				subdirs = subdirs + 1
			end

			DownloadFolder(str .. "/" .. v)

			subdirs = subdirs - 1
		end

	end

	if root and debuggingDownloads then
		subdirs = subdirs - 1
		print("\n")
	end
end

timer.Simple(0, function()
	for i=1, #BWAddons do
		resource.AddWorkshop(tostring(BWAddons[i]))
	end

	DownloadFolder("materials/vgui/prestige")

	DownloadFolder("materials/vgui/runes")

	DownloadFolder("materials/vgui/misc")

	DownloadFolder("models/player/wiltos")

	DownloadFolder("materials/grp")
	DownloadFolder("materials/zerochain")
	DownloadFolder("materials/models/props/computers")

	DownloadFolder("models/grp")
	DownloadFolder("models/zerochain")

	DownloadFolder("resource/fonts", "*.ttf")

	DownloadFolder("sound/gachi")
	DownloadFolder("sound/dash")
	DownloadFolder("sound/snds")
	DownloadFolder("sound/playsound")
	DownloadFolder("sound/stims")
	DownloadFolder("sound/mus")
	DownloadFolder("sound/vgui")
end)