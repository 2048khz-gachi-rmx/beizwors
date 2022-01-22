FInc.Recursive("stims/sh_*.lua", FInc.SHARED, nil, FInc.RealmResolver())
FInc.Recursive("stims/sv_*.lua", FInc.SERVER, nil, FInc.RealmResolver())
FInc.Recursive("stims/cl_*.lua", FInc.CLIENT, nil, FInc.RealmResolver():SetVerbose(true))

if SERVER then
	include("vmanip/anims/stimpaks.lua")
end