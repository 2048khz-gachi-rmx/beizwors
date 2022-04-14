att.PrintName = "7.62x39 45rnd Mag"
att.Icon = Material("vgui/fas2atts/545_45rnd")
att.Description = "45-round magazine for 7.62x39 ammo, for AK-47 and compatible systems. Also a standard issue RPK-47 magazine."

att.AutoStats = true
att.Slot = "fas2_762_45rnd"

att.MagExtender = true

att.Override_ClipSize = 45

att.ActivateElements = {"45rnd"}

att.Hook_Compatible = function(wep)
    if (wep.RegularClipSize or wep.Primary.ClipSize) == wep.ExtendedClipSize then return false end
end