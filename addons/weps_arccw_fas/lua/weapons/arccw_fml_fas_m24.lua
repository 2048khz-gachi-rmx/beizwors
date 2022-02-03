SWEP.Base = "arccw_base"
SWEP.Spawnable = true -- this obviously has to be set to true
SWEP.Category = "ArcCW - FA:S1" -- edit this if you like
SWEP.AdminOnly = false

SWEP.PrintName = "SW24"
SWEP.TrueName = "M24"
SWEP.Trivia_Class = "Sniper Rifle"
SWEP.Trivia_Desc = "A [Modified] Remington Model 700 rifle. The M24 has the 'long action' bolt version of the Remington 700 receiver but is chambered for the 7.62×51mm NATO that has an overall length of 69.85mm. Use a cut downed M16A2 ironsight for some reason."
SWEP.Trivia_Manufacturer = "Remington Arms"
SWEP.Trivia_Calibre = "7.62×51mm NATO"
SWEP.Trivia_Country = "United States"
SWEP.Trivia_Year = "1988"

if GetConVar("arccw_truenames"):GetBool() then SWEP.PrintName = SWEP.TrueName end

SWEP.Slot = 2

SWEP.UseHands = true

SWEP.CrouchPos = Vector(-1, -2, -0.5)
SWEP.CrouchAng = Angle(0, 0, -20)

SWEP.ViewModel = "models/weapons/arccw/fml/fas1/c_m24.mdl"
SWEP.WorldModel = "models/weapons/arccw/fml/fas1/w_m24.mdl"
SWEP.ViewModelFOV = 70

SWEP.Damage = 80
SWEP.DamageMin = 150 -- damage done at maximum range
SWEP.Range = 55 -- in METRES
SWEP.Penetration = 40
SWEP.DamageType = DMG_BUCKSHOT
SWEP.ShootEntity = nil -- entity to fire, if any
SWEP.MuzzleVelocity = 150 -- projectile or phys bullet muzzle velocity
-- IN M/S

SWEP.TracerNum = 1 -- tracer every X
SWEP.TracerCol = Color(255, 25, 25)
SWEP.TracerWidth = 3

SWEP.ChamberSize = 1 -- how many rounds can be chambered.
SWEP.Primary.ClipSize = 5 -- DefaultClip is automatically set.
SWEP.ExtendedClipSize = 10
SWEP.ReducedClipSize = 3

SWEP.Recoil = 4
SWEP.RecoilSide = 1

SWEP.ShotgunReload = true
SWEP.ManualAction = true

SWEP.Delay = 60 / 100 -- 60 / RPM.
SWEP.Num = 1 -- number of shots per trigger pull.
SWEP.RunawayBurst = false
SWEP.Firemodes = {
    {
        PrintName = "BOLT",
        Mode = 1,
    },
    {
        Mode = 0
    }
}

SWEP.NPCWeaponType = {"weapon_ar2", "weapon_crossbow"}
SWEP.NPCWeight = 80

SWEP.AccuracyMOA = 0.03 -- accuracy in Minutes of Angle. There are 60 MOA in a degree.
SWEP.HipDispersion = 850 -- inaccuracy added by hip firing.
SWEP.MoveDispersion = 100

SWEP.NoLastCycle = true

SWEP.Primary.Ammo = "SniperPenetratedRound" -- what ammo type the gun uses
SWEP.MagID = "bfg" -- the magazine pool this gun draws from

SWEP.ShootVol = 120 -- volume of shoot sound
SWEP.ShootPitch = 100 -- pitch of shoot sound

SWEP.ShootSound = "weapons/arccw_fml/sniper_m24/m24_fire1.wav", "weapons/arccw_fml/sniper_m24/m24_fire2.wav", "weapons/arccw_fml/sniper_m24/m24_fire3.wav", "weapons/arccw_fml/sniper_m24/m24_fire4.wav","weapons/arccw_fml/sniper_m24/m24_fire5.wav"
SWEP.ShootSoundSilenced = "weapons/arccw_fml/fas1_suppr/m24.wav"
SWEP.DistantShootSound = "weapons/arccw/awp/awp1-distant.wav"

SWEP.MuzzleEffect = "muzzleflash_1"
SWEP.ShellModel = "models/shells/shell_338mag.mdl"
SWEP.ShellPitch = 80
SWEP.ShellScale = 1.5

SWEP.MuzzleEffectAttachment = 1 -- which attachment to put the muzzle on
SWEP.CaseEffectAttachment = 2 -- which attachment to put the case effect on

SWEP.SightTime = 0.31
SWEP.SpeedMult = 0.85
SWEP.SightedSpeedMult = 0.45

SWEP.BulletBones = { -- the bone that represents bullets in gun/mag
    -- [0] = "bulletchamber",
    -- [1] = "bullet1"
}

SWEP.ProceduralRegularFire = false
SWEP.ProceduralIronFire = false

SWEP.CaseBones = {}

SWEP.IronSightStruct = {
    Pos = Vector(-3.721, -5, -0.102),
    Ang = Angle(0.495, 0, 0),
    Magnification = 1.1,
    SwitchToSound = "", -- sound that plays when switching to this sight
}


SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "shotgun"
SWEP.HoldtypeSights = "ar2"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN

SWEP.ActivePos = Vector(0, -4, -2)
SWEP.ActiveAng = Angle(0.6, 0.8, 0)

SWEP.HolsterPos = Vector(3, -2, 3.011)
SWEP.HolsterAng = Angle(-24, 18.613, 4)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.AttachmentElements = {
    ["mag_cum"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
        WMBodygroups = {{ind = 1, bg = 1}},
    },
    ["nors"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
        WMBodygroups = {{ind = 2, bg = 1}},
    },	
}

SWEP.Attachments = {
    {
        PrintName = "Optic", -- print name
        DefaultAttName = "Iron Sights",
        Slot = {"optic", "optic_lp", "optic_sniper"}, -- what kind of attachments can fit here, can be string or table
        Bone = "Weapon", -- relevant bone any attachments will be mostly referring to
        Offset = {
            vpos = Vector(0, -3.2, 10), -- offset that the attachment will be relative to the bone
            vang = Angle(90, 0, -90),
            wpos = Vector(10, 0.5, -6),
            wang = Angle(-9.738, 0, 180)
        },
		ExtraSightDist = 8,
        InstalledEles = {"nors"}
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "Standard Muzzle",
        Slot = "muzzle",
        Bone = "Weapon",
        Offset = {
            vpos = Vector(0, -2.1, 48),
            vang = Angle(90, 0, -90),
            wpos = Vector(37, 0.782, -9.8),
            wang = Angle(-9.79, 0, 180)
        },
		VMScale = Vector(1.5,1.5,1.5),		
    },
    {
        PrintName = "Underbarrel",
        Slot =  {"foregrip", "bipod"},
        Bone = "Weapon",
        Offset = {
            vang = Angle(90,0, -90),
            wpos = Vector(18.329, 0.602, -4.153),
            wang = Angle(-10.216, 0, 180)
        },
        SlideAmount = {
            vmin = Vector(0, 0, 14),
            vmax = Vector(0, -0.5, 20),
            wmin = Vector(20, 0.832, -5),
            wmax = Vector(20, 0.832, -5),
        },	
    },
    {
        PrintName = "Tactical",
        Slot = "tac",
        Bone = "Weapon",
        Offset = {
            vpos = Vector(-1, -1.2, 15), -- offset that the attachment will be relative to the bone
            vang = Angle(90, 0, 180),
            wpos = Vector(15.625, -0.253, -6.298),
            wang = Angle(-8.829, -0.556, 90)
        },
    },
    {
        PrintName = "Grip",
        Slot = "grip",
        DefaultAttName = "Standard Grip"
    },
    {
        PrintName = "Stock",
        Slot = "stock",
        DefaultAttName = "Standard Stock",
        InstalledEles = {"stock"},
    },
    {
        PrintName = "Ammo Type",
        Slot = {"ammo_bullet"}
    },	
    {
        PrintName = "Perk",
        Slot = {"perk", "perk_fas_mag_fed", "perk_fas_bolt"}
    },
    {
        PrintName = "Charm",
        DefaultAttName = "None",
        Slot = {"fml_charm", "charm"},
        Bone = "Weapon",
        Offset = {
            vpos = Vector(1, -0.5, 8), -- offset that the attachment will be relative to the bone
            vang = Angle(90, 0, -90),
            wpos = Vector(8, 1, -3),
            wang = Angle(-9, 0, 180)
        },
		FreeSlot = true,
    },		
}

SWEP.RejectAttachments = {
    ["perk_fastreload"] = true	
}


SWEP.MaxRecoilBlowback = 0.5

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
    },
    ["draw"] = {
        Source = "draw",
        LHIK = false,
        SoundTable = {{s = "weapons/arccw/sawedoff/sawedoff_draw.wav", t = 0}},
    },
    ["ready"] = {
        Source = "deploy",
        LHIK = false,
    },
    ["fire"] = {
        Source = {"fire"},
        Time = 30/60,
    },
    ["fire_iron"] = {
        Source = {"iron"},
    },	
    ["slam"] = {
        Source = "slam",
        Time = 60/60,		
        ShellEjectAt = 19/60,
    },
    ["cycle"] = {
        Source = "pump",
        ShellEjectAt = 30/60,
    },
    ["sgreload_start"] = {
        Source = "reload_start",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        LHIK = true,
        LHIKIn = 0.2,
        LHIKOut = 0.2,
    },
    ["sgreload_start_empty"] = {
        Source = "reload_empty_start",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        ShellEjectAt = 30/60,		
        LHIK = false,
        LHIKIn = 0.5,
        LHIKOut = 0,
    },
    ["sgreload_insert"] = {
        Source = "reload_shell",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        TPAnimStartTime = 0.3,
        LHIK = false,
        LHIKIn = 0,
        LHIKOut = 0,
    },
    ["sgreload_finish"] = {
        Source = "reload_end",
        LHIK = false,
        LHIKIn = 0,
        LHIKOut = 0.4,
    },
    ["reload"] = {
        Source = "mag_fed_wet",	
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {20, 39},		
        LHIK = false,
        LHIKIn = 0.5,
        LHIKOut = 0.4,
    },
    ["reload_empty"] = {
        Source = "mag_fed_dry",	
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {20, 39},		
        ShellEjectAt = 43/60,		
        LHIK = false,
        LHIKIn = 0.3,
        LHIKOut = 0.6,
    },
}