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
