SWEP.Base = "arccw_base"
SWEP.Spawnable = true -- this obviously has to be set to true
SWEP.Category = "ArcCW - FA:S1" -- edit this if you like
SWEP.AdminOnly = false

SWEP.PrintName = "Mutant 47"
SWEP.TrueName = "AKM15"
SWEP.Trivia_Class = "Assault Rifle"
SWEP.Trivia_Desc = "Open bolt AK with forward assist for bolt catch. Please help me I have 2 days to live."
SWEP.Trivia_Manufacturer = "Beyond Hell"
SWEP.Trivia_Calibre = "7.62x56mm NATO"
SWEP.Trivia_Mechanism = "How"
SWEP.Trivia_Country = "Russo America"
SWEP.Trivia_Year = "1969"

SWEP.Slot = 2

SWEP.NPCWeaponType = {"weapon_ar2", "weapon_smg1"}
SWEP.NPCWeight = 160

SWEP.CrouchPos = Vector(-4.5, 0, 0.5)
SWEP.CrouchAng = Angle(0, 0, -45)

if GetConVar("arccw_truenames"):GetBool() then SWEP.PrintName = SWEP.TrueName end

SWEP.UseHands = true

SWEP.ViewModel = "models/weapons/arccw/fml/fas1/c_extra_akm15.mdl"
SWEP.WorldModel = "models/weapons/arccw/fml/fas1/w_akm15.mdl"
SWEP.ViewModelFOV = 70

SWEP.Damage = 34
SWEP.DamageMin = 17 -- damage done at maximum range
SWEP.Range = 90 -- in METRES
SWEP.Penetration = 6
SWEP.DamageType = DMG_BULLET
SWEP.ShootEntity = nil -- entity to fire, if any
SWEP.MuzzleVelocity = 1100 -- projectile or phys bullet muzzle velocity
-- IN M/S

SWEP.TracerNum = 1 -- tracer every X
SWEP.TracerCol = Color(255, 25, 25)
SWEP.TracerWidth = 3

SWEP.ChamberSize = 1 -- how many rounds can be chambered.
SWEP.Primary.ClipSize = 30 -- DefaultClip is automatically set.
SWEP.ExtendedClipSize = 40
SWEP.ReducedClipSize = 20

SWEP.Recoil = 0.6
SWEP.RecoilSide = 0.15
SWEP.RecoilRise = 0.4
SWEP.VisualRecoilMult = 0.5

SWEP.Delay = 60 / 700 -- 60 / RPM.
SWEP.Num = 1 -- number of shots per trigger pull.
SWEP.Firemodes = {
    {
        Mode = 2,
    },
    {
        Mode = 1,
    },
    {
        Mode = 0
    }
}

SWEP.AccuracyMOA = 10 -- accuracy in Minutes of Angle. There are 60 MOA in a degree.
SWEP.HipDispersion = 550 -- inaccuracy added by hip firing.

SWEP.Primary.Ammo = "ar2" -- what ammo type the gun uses
SWEP.MagID = "type2" -- the magazine pool this gun draws from

SWEP.ShootVol = 115 -- volume of shoot sound
SWEP.ShootPitch = 100 -- pitch of shoot sound

SWEP.ShootSound = "weapons/arccw_fml/ar_sako92/sako_fire1.wav"
SWEP.ShootSound = "weapons/arccw_fml/ar_sako92/sako_fire2.wav", "weapons/arccw_fml/ar_sako92/sako_fire3.wav", "weapons/arccw_fml/ar_sako92/sako_fire4.wav","weapons/arccw_fml/ar_sako92/sako_fire5.wav"
SWEP.ShootSoundSilenced = "weapons/arccw_fml/fas1_suppr/akm15.wav"
SWEP.DistantShootSound = "weapons/arccw/ak47/ak47-1-distant.wav"

SWEP.MuzzleEffect = "muzzleflash_1"
SWEP.ShellModel = "models/shells/shell_762nato.mdl"
SWEP.ShellScale = 1.5
SWEP.ShellMaterial = "models/weapons/arcticcw/shell_556_steel"

SWEP.MuzzleEffectAttachment = 1 -- which attachment to put the muzzle on
SWEP.CaseEffectAttachment = 2 -- which attachment to put the case effect on

SWEP.SpeedMult = 0.94
SWEP.SightedSpeedMult = 0.5
SWEP.SightTime = 0.3
SWEP.VisualRecoilMult = 1.15

SWEP.BulletBones = { -- the bone that represents bullets in gun/mag
    -- [0] = "bulletchamber",
    -- [1] = "bullet1"
}

SWEP.ProceduralRegularFire = false
SWEP.ProceduralIronFire = false

SWEP.CaseBones = {}

SWEP.IronSightStruct = {
    Pos = Vector(-2.339, -5, -0.401),
    Ang = Angle(0, 0, 0),
    Magnification = 1.1,
    SwitchToSound = "", -- sound that plays when switching to this sight
}

SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0, 0, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(10, -6, -4.011)
SWEP.HolsterAng = Angle(1.898, 54.613, -10.113)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.BarrelLength = 30

SWEP.AttachmentElements = {
    ["noch"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
        WMBodygroups = {{ind = 1, bg = 1}},
    },
    ["bkrail"] = {
     VMElements = {
        {
            Model = "models/weapons/arccw/atts/backup_rail.mdl",
              Bone = "Weapon_Main",
             Offset = {
                 pos = Vector(0, -4, 13),
                ang = Angle(180, 90, 180),
           },
		 },
      }
    },		
}

SWEP.RejectAttachments = {
    ["perk_fastreload"] = true	
}

SWEP.ExtraSightDist = 4

SWEP.Attachments = {
    {
        PrintName = "Optic", -- print name
        DefaultAttName = "Iron Sights",
        Slot = {"optic", "optic_lp"}, -- what kind of attachments can fit here, can be string or table
        Bone = "Weapon_Main", -- relevant bone any attachments will be mostly referring to
        Offset = {
            vpos = Vector(0, -4.1, 4.2), -- offset that the attachment will be relative to the bone
            vang = Angle(90, 0, -90),
            wpos = Vector(7, 0.739, -5),
            wang = Angle(-10, 0, 180)
        },
        InstalledEles = {"noch"},			
    },
    {
        PrintName = "Backup Optic", -- print name
        Slot = {"optic_lp"}, -- what kind of attachments can fit here, can be string or table
        Bone = "Weapon_Main", -- relevant bone any attachments will be mostly referring to
        Offset = {
            vpos = Vector(-0.7, -4.4, 13), -- offset that the attachment will be relative to the bone
            vang = Angle(90, 0, -45),
            wpos = Vector(15, 0.832, -5),
            wang = Angle(-10.393, 0, -135)
        },	
        InstalledEles = {"bkrail"},		
        KeepBaseIrons = true,
		ExtraSightDist = 12	
    },	
    {
        PrintName = "Muzzle",
        DefaultAttName = "Standard Muzzle",
        Slot = "muzzle",
        Bone = "Weapon_Main",
        Offset = {
            vpos = Vector(0, -3, 17.5),
            vang = Angle(90, 0, -90),
            wpos = Vector(21, 0.782, -6.2),
            wang = Angle(-9.79, 0, 180)
        },
    },	
    {
        PrintName = "Underbarrel",
        Slot = {"foregrip", "ubgl", "bipod"},
        Bone = "Weapon_Main",
        Offset = {
            vang = Angle(90,0, -90),
            wang = Angle(-10.216, 0, 180)
        },
        SlideAmount = {
            vmin = Vector(0, -2, 10),
            vmax = Vector(0, -2, 15),
            wmin = Vector(15, 0.832, -5),
            wmax = Vector(15, 0.832, -5),
        },			
    },
    {
        PrintName = "Tactical",
        Slot = "tac",
        Bone = "Weapon_Main",
        Offset = {
            vpos = Vector(-0.8, -2.5, 11), -- offset that the attachment will be relative to the bone
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
        DefaultAttName = "Standard Stock"
    },
    {
        PrintName = "Fire Group",
        Slot = "fcg",
        DefaultAttName = "Standard FCG"
    },
    {
        PrintName = "Ammo Type",
        Slot = {"ammo_bullet"}
    },
    {
        PrintName = "Perk",
        Slot = {"perk", "perk_fas"}
    },	
    {
        PrintName = "Charm",
        DefaultAttName = "None",
        Slot = {"fml_charm", "charm"},
        Bone = "Weapon_Main",
        Offset = {
            vpos = Vector(0.5, -2, 8),
            vang = Angle(90, 0, -90),
            wpos = Vector(5, 1, -3),
            wang = Angle(-9, 0, 180)
        },
		FreeSlot = true,
    },		
}

SWEP.Animations = {
    ["draw"] = {
        Source = "draw",
        Time = 35/60,
        SoundTable = {{s = "weapons/arccw/ak47/ak47_draw.wav", t = 0}},
        LHIK = true,
        LHIKIn = 1,
        LHIKOut = 1,
    },
    ["ready"] = {
        Source = "deploy",
        Time = 75/60,
        SoundTable = {{s = "weapons/arccw/ak47/ak47_draw.wav", t = 0}},		
        LHIK = false,
        LHIKIn = 0,
        LHIKOut = 0.25,
    },
    ["fire"] = {
        Source = {"fire"},
        Time = 30/60,
        ShellEjectAt = 0,
    },
    ["fire_iron"] = {
        Source = "iron",
        Time = 30/60,
        ShellEjectAt = 0,
    },
    ["reload"] = {
        Source = "wet",
        Time = 140/60,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {20, 39},
        FrameRate = 60,
        LHIK = false,
        LHIKIn = 0.5,
        LHIKOut = 0.715,
    },
    ["reload_empty"] = {
        Source = "dry",
        Time = 190/60,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {37, 58, 75, 92, 119, 124},
        FrameRate = 60,
        LHIK = false,
        LHIKIn = 0.5,
        LHIKOut = 0.5,
    },
    ["reload_soh"] = {
        Source = "soh_wet",
        Time = 120/60,	
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {24, 42, 59, 71, 89},
        FrameRate = 60,
        LHIK = false,
        LHIKIn = 0.5,
        LHIKOut = 0.35,
    },
    ["reload_empty_soh"] = {
        Source = "soh_dry",
        Time = 150/60,		
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {24, 42, 59, 71, 89},
        FrameRate = 60,
        LHIK = false,
        LHIKIn = 0.2,
        LHIKOut = 0.35,
    },		
}