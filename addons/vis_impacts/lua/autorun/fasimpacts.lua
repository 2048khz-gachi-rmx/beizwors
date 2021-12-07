if CLIENT then
	game.AddParticles("particles/impact_fx.pcf")
	game.AddParticles("particles/water_impact.pcf")
end

hook.Add( "PopulateToolMenu", "CustomFASSettings", function()

	spawnmenu.AddToolMenuOption( "Utilities", "FAS Alpha","Froze_Menu","Enable Impact", "","", function( panel ) 
	panel:CheckBox("Enable Impact Effects?","cl_new_impact_effects")
	
	end)

end )