--

if not AIBases.AIBase then
	include("sh_metas.lua")
end


local base = AIBases.AIBase:new("test")
local lock = base:CreateLock()

lock:SetPos(Vector (-543.96875, 1551.1947021484, -373.138671875))
lock:SetAngle(Angle(180, 0, 0))

lay = AIBases.BaseLayout:new()
