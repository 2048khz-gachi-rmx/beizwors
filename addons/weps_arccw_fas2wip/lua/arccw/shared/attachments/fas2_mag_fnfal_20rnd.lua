att.PrintName = "FN Fal 20RND Magazine"
att.Icon = Material("vgui/fas2atts/fnfal20mag")
att.Description = "Extended magazine for FN Fal."

att.AutoStats = true
att.Slot = "fas2_fnfalmag"

att.MagExtender = true 

att.Override_ClipSize = 20

att.ActivateElements = {"mag"}

att.Hook_Compatible = function(wep)
    if (wep.RegularClipSize or wep.Primary.ClipSize) == wep.ExtendedClipSize then return false end
end