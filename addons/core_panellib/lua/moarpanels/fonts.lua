setfenv(1, _G)
Fonts = Fonts or {}

--[[
	TODO: delete fonts that you don't use
	cuz as of 04.05.21 it's 19x15 = 285 fonts
]]


local families = {
	["Roboto"] = "R",
	["Roboto Light"] = "RL",

	["Titillium Web"] = "TW",
	["Titillium Web SemiBold"] = "TWB",

	["Open Sans"] = "OS",
	["Open Sans SemiBold"] = "OSB",
	["Open Sans Light"] = "OSL",

	["Arial"] = "A",
	["Helvetica"] = "HL",

	["Exo Regular"] = "EX",
	["Exo SemiBold"] = "EXSB",
	["Exo Bold"] = "EXB",
	["Exo Medium"] = "EXM",

	["Montserrat"] = "MR",
	["Montserrat Medium"] = "MRM",
	["Montserrat Bold"] = "MRB",

	["SnareDrum Zero NBP"] = "SDZ",
	["SnareDrum Two NBP"] = "SDT",

	["BreezeSans"] = "BS",
	["BreezeSans Medium"] = "BSSB",
	["BreezeSans Light"] = "BSL",
	["BreezeSans Bold"] = "BSB",

	["DejaVu Sans"] = "DV",

	["Sydnie"] = "SYD"
}

FontFamilies = families

local sizes = {12, 14, 16, 18, 20, 22, 24, 28, 32, 36, 44, 48, 56, 64, 72, 96, 128}

for k,v in pairs(families) do

	for _, size in pairs(sizes) do
		if not Fonts[v .. size] then
			surface.CreateFont(v .. size, {
				font = k,
				size = size,
				weight = 400,
			})

			Fonts[v .. size] = k
		end
	end

end

-- only works with fonts made above ^
function Fonts.PickFont(fam, txt, wid, hgt, start_size)
	start_size = start_size or 128
	hgt = hgt or wid

	local picked = fam .. start_size

	for i=#sizes, 1, -1 do
		local sz = sizes[i]

		if sz > start_size then continue end

		surface.SetFont(fam .. sz)
		local tw = surface.GetTextSize(txt)

		if tw <= wid and sz < hgt then
			return fam .. sz, sz
		end
	end

	return picked, sz
end

function Fonts.ClosestSize(h)
	for i=#sizes, 1, -1 do
		if sizes[i] <= h then
			return sizes[i]
		end
	end
end