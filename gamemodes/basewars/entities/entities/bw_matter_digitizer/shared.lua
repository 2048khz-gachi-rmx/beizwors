AddCSLuaFile()

ENT.Base = "bw_base_electronics"
ENT.Type = "anim"
ENT.PrintName = "Matter Digitizer"

ENT.Model = "models/props_combine/combine_mortar01b.mdl"
ENT.Skin = 0

ENT.CanTakeDamage = true
ENT.NoHUD = false

ENT.SubModels = {
	{
		Ang      = Angle (  0.047310583293438, -89.875785827637   , - 0.21090526878834 ),
		Material = "",
		Model    = "models/props_combine/breenconsole.mdl",
		Pos      = Vector (-32.690765380859   ,   1.6189754009247  , - 0.94484406709671 )
	}, {
		Ang      = Angle (  89.980911254883  , -179.87663269043   ,    0               ),
		Material = "",
		Model    = "models/props_combine/combinebutton.mdl",
		Pos      = Vector (-  0.28220677375793,    2.2998285293579 ,   42.15901184082   )
	}

}
function ENT:DerivedDataTables()

end