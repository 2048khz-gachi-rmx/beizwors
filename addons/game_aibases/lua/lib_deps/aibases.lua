AIBases = AIBases or {}

FInc.Recursive("aibases/*.lua", FInc.SHARED, FInc.RealmResolver())
FInc.Recursive("aibases/classes/*.lua", FInc.SHARED, FInc.RealmResolver():SetDefault(true))

FInc.Recursive("aibases/server/*.lua", FInc.SERVER, FInc.RealmResolver())
FInc.Recursive("aibases/client/*.lua", FInc.CLIENT, FInc.RealmResolver())

function ReloadNavs()
	if SERVER then
		navmesh.Load()
	end

	AIBases.Builder.NWNav:Invalidate()
	include("aibases/sh_nav_tool.lua")
	FInc.Recursive("aibases/client/*.lua", FInc.CLIENT, FInc.RealmResolver())
end

--[[
lay = AIBases.BaseLayout:new() lay:ReadFrom("test4") lay:Spawn()
]]