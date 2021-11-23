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

local name = "glue/arccw_fas_atts_%d.lua"

local toW = {beginning}
local curLen = 0
local num = 1

local function awful(s)
	return s--:gsub("%f[\r\n][\r\n]+%f[^\r\n]", "\r\n")
end


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