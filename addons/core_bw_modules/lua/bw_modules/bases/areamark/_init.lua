if _wAODIJAHOD then return end



AddCSLuaFile()

StartTool("AreaMark")
BaseWars.Bases.MarkTool = TOOL
EndTool(TOOL)

_wAODIJAHOD = true
	FInc.FromHere("*.lua", FInc.SHARED, false, FInc.RealmResolver():SetDefault(true))
_wAODIJAHOD = nil

FInc.OnStates(function()
	-- mfw including with mysqloo anywhere on the stack causes relative pathing to die
	include(file.Here() .. "areamark_sh.lua")
	include(file.Here() .. "areamark_" .. Rlm():lower() .. ".lua")
	BaseWars.Bases.MarkTool:Finish()
end, CLIENT or "BW_SQLAreasFetched")

