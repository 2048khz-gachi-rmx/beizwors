att.PrintName = "(CS+) Magnum Buckshot"
att.Icon = Material("entities/acwatt_ammo_magnum.png")
att.Description = "Powerful overloaded rounds deal extra damage at close range, but at the cost of increased recoil, spread, and long-range damage."
att.Desc_Pros = {
}
att.Desc_Cons = {
}
att.AutoStats = true
att.Slot = "go_ammo"
att.InvAtt = "ammo_magnum"

att.Mult_ShootPitch = 0.9
att.Mult_Damage = 1.25
att.Mult_DamageMin = 1
att.Mult_Penetration = 1.25
att.Mult_Range = 0.8
att.Mult_Recoil = 1.2
att.Mult_AccuracyMOA = 1.5

att.Hook_Compatible = function(wep)
    if !wep:GetIsShotgun() then return false end
end