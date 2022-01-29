CreateClientConVar( "cl_fas2pms_skin_hand",		1, true, true, nil, 1, 4 )
CreateClientConVar( "cl_fas2pms_skin_glove",	1, true, true, nil, 1, 4 )
CreateClientConVar( "cl_fas2pms_skin_sleeve",	1, true, true, nil, 1, 2 )

if CLIENT then
	local NumberToTexture = {
		[1] = "models/weapons/fas-2hands/hand",
		[2] = "models/weapons/fas-2hands/hand_tan",
		[3] = "models/weapons/fas-2hands/hand_black",
		[4] = "models/weapons/fas-2hands/hand_camo"
	}

	local NumberToGlove = {
		[1] = "models/weapons/fas-2hands/nomex",
		[2] = "models/weapons/fas-2hands/black",
		[3] = "models/weapons/fas-2hands/desertkhaki",
		[4] = "models/weapons/fas-2hands/multicam"
	}

	local NumberToSleeve = {
		[1] = "models/weapons/fas-2hands/sleeve",
		[2] = "models/weapons/fas-2hands/sleeve2"
	}

	local conv = {
		"cl_fas2pms_skin_hand",
		"cl_fas2pms_skin_glove",
		"cl_fas2pms_skin_sleeve"
	}

	matproxy.Add( {
		name = "FAS2_PMs_Hands",
		init = function( self, mat, values )
			self.ResultTo = values.resultvar
		end,
		bind = function( self, mat, ent )
			local Type = self.ResultTo
			local muah

			if Type == 1 then
				muah = NumberToTexture
			elseif Type == 2 then
				muah = NumberToGlove
			else
				muah = NumberToSleeve
			end


			local t = muah[GetConVar(conv[Type]):GetInt() or 1]

			if t then
				mat:SetTexture( "$basetexture", t )
			end
		end
	} )

	local vec = Vector()

	matproxy.Add( {
		name = "ArcCW_FAS2_Color_Crosshair",
		bind = function( self, mat, ent )
			local r = GetConVar("arccw_fas2_tri_clr_r"):GetFloat()
			local g = GetConVar("arccw_fas2_tri_clr_g"):GetFloat()
			local b = GetConVar("arccw_fas2_tri_clr_b"):GetFloat()

			if muah then
				vec:SetUnpacked(r / 255, g / 255, b / 255)
				mat:SetVector( "$color2", vec )
			end
		end
	} )
end
