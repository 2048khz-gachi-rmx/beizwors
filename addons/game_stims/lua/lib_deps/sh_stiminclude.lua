FInc.Recursive("stims/sh_*.lua", FInc.SHARED, FInc.RealmResolver())
FInc.Recursive("stims/sv_*.lua", FInc.SERVER, FInc.RealmResolver())
FInc.Recursive("stims/cl_*.lua", FInc.CLIENT, FInc.RealmResolver():SetVerbose(true))

if SERVER then
	include("vmanip/anims/stimpaks.lua")
end