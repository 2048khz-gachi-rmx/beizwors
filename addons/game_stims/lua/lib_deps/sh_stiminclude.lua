FInc.Recursive("stims/sh_*.lua", _SH, nil, FInc.RealmResolver())
FInc.Recursive("stims/sv_*.lua", _SV, nil, FInc.RealmResolver())
FInc.Recursive("stims/cl_*.lua", _CL, nil, FInc.RealmResolver():SetVerbose(true))

if SERVER then
	include("vmanip/anims/stimpaks.lua")
end