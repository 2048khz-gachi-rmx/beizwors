att.PrintName = "Proficiency"
att.Icon = Material("vgui/fas2atts/proficiency")
att.Description = "Improves reloading speed and weapon handling."

att.Desc_Pros = {
	"Faster reloads"
}

att.Slot = "fas2_nomen"

att.Hook_SelectReloadAnimation = function(wep, anim)
	local rel = wep.Animations["reload_nomen"] and "_nomen" or ""
	local empty = wep:Clip1() == 0 and "_empty" or ""

	if GetConVar("developer"):GetBool() and rel == "" then print(anim .. " Nomen Anim Not Found.") end

	return "reload" .. rel .. empty
end

att.AutoStats = true

att.AttachSound = "fas2/cstm/attach.wav"
att.DetachSound = "fas2/cstm/detach.wav"