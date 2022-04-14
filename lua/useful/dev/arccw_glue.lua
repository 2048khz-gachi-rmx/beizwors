local fmt = [[
------
-- %s
------

do
	local att = {}
	ArcCW.SetShortName("%s")

%s
	ArcCW.LoadAttachmentType(att)
end

]]

local beginning = [[
local Material = ArcCW.AttachmentMat

]]

require("gaceio")

file.CreateDir("glue/")

local outPath = "garrysmod/data/glue/arccw_tuna_atts_%d.lua"

local toW = {beginning}
local curLen = 0
local num = 1

local function awful(s)
	return s--:gsub("%f[\r\n][\r\n]+%f[^\r\n]", "\r\n")
end

local function flush()
	local str = table.concat(toW)
	print(gaceio.Write(outPath:format(num), str))
	num = num + 1
	curLen = 0
	toW = {beginning}

	print("flushed", outPath:format(num), #str)
end

local folder = "weps_arccw_tuna"
local path = "addons/" .. folder .. "/lua/arccw/shared/attachments/"

for k,v in pairs(file.Find(path .. "*.lua", "GAME")) do
	local dat = file.Read(path .. v, "GAME")
	local subdat = {}
	for s in eachNewline(dat) do
		if s:match("[^%c]") then subdat[#subdat + 1] = "	" .. s end
	end

	dat = table.concat(subdat, "\n")

	toW[#toW + 1] = fmt:format(v, v:gsub("%.lua", ""), dat)

	if curLen + #dat > 64000 then
		flush()
	end

	curLen = curLen + #dat
end
flush()

--[=[
local data = {
	"local temp",
}

local fmt =
[[
temp = Inventory.BaseItemObjects.Weapon:new("%s")

temp    :SetName("%s")
        :SetModel("%s")
        :SetWeaponClass("%s")

        :SetCamPos( Vector(3.5, -34, 6.7) )
        :SetLookAng( Angle(5.9, 90.4, 20) )
        :SetFOV( 19 )

        :SetShouldSpin(false)

        :SetEquipSlot("%s")
]]


local pool = Inventory.Blueprints.WeaponPool
require("gaceio")

for typ, dat in pairs(pool) do
	for _, class in ipairs(dat) do
		local wep = weapons.GetStored(class)
		local entry = fmt:format(
			class,
			wep.PrintName,
			wep.WorldModel,
			class,
			typ == "pistol" and "secondary" or "primary")

		data[#data + 1] = entry
	end

	local strData = table.concat(data)
	gaceio.Write("data/invfill/" .. typ .. ".lua", strData)
end


]=]