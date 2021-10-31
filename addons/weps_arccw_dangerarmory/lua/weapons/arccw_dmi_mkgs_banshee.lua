SWEP.Base = "arccw_base"
SWEP.Spawnable = true -- this obviously has to be set to true
SWEP.Category = "ArcCW - Danger Armory" -- edit this if you like
SWEP.AdminOnly = false

SWEP.PrintName = "Phantasm-9"
SWEP.TrueName = "MKGS Banshee"
SWEP.Trivia_Class = "Short Barreled Rifle"
SWEP.Trivia_Desc = "The MKGS Banshee semi-automatic Short Barreled Rifle (SBR) is a compact 9mm carbine that is patterned after the tried and true AR-15 weapons platform and fires a 9x19mm Parabellum round. It accepts most Glock magazines making it economical with with comes to ammunition logistics. This weapon is suitable for home defense and competition shooting. It comes standard with a Magpul MOE pistol grip, RML M-LOK handguard, and CMMG’s Cerakote finish"
SWEP.Trivia_Manufacturer = "CMMG"
SWEP.Trivia_Calibre = "9x19mm Para"
SWEP.Trivia_Country = "United States"
SWEP.Trivia_Year = "2018"

if GetConVar("arccw_truenames"):GetBool() then SWEP.PrintName = SWEP.TrueName end

SWEP.Slot = 2

SWEP.NPCWeaponType = "weapon_smg1"
SWEP.NPCWeight = 155

SWEP.UseHands = true

SWEP.ViewModel = "models/weapons/arccw/dm1973/c_dmi_mkgs_banshee.mdl"
SWEP.WorldModel = "models/weapons/arccw/dm1973/w_dmi_mkgs_banshee.mdl"
SWEP.ViewModelFOV = 70

SWEP.DefaultBodygroups = "000000"

SWEP.NPCWeaponType = "weapon_smg1"
SWEP.NPCWeight = 120

SWEP.Damage = 24
SWEP.DamageMin = 12 -- damage done at maximum range
SWEP.Range = 50 -- in METRES
SWEP.Penetration = 2
SWEP.DamageType = DMG_BULLET
SWEP.ShootEntity = nil -- entity to fire, if any
SWEP.MuzzleVelocity = 400 -- projectile or phys bullet muzzle velocity
-- IN M/S

SWEP.CrouchPos = Vector(-6.2, 0, 0.5)
SWEP.CrouchAng = Angle(0, 0, -45)

SWEP.TracerNum = 1 -- tracer every X
SWEP.TracerCol = Color(255, 25, 25)
SWEP.TracerWidth = 3

SWEP.ChamberSize = 1 -- how many rounds can be chambered.
SWEP.Primary.ClipSize = 33 -- DefaultClip is automatically set.
SWEP.ExtendedClipSize = 50
SWEP.ReducedClipSize = 18

SWEP.Recoil = 0.375
SWEP.RecoilSide = 0.35
SWEP.RecoilRise = 0.75
SWEP.VisualRecoilMult = 0.3

SWEP.Delay = 60 / 800 -- 60 / RPM.
SWEP.Num = 1 -- number of shots per trigger pull.
SWEP.Firemodes = {
    {
        Mode = 1,
    },
    {
        Mode = 0
    }
}

SWEP.AccuracyMOA = 5 -- accuracy in Minutes of Angle. There are 60 MOA in a degree.
SWEP.HipDispersion = 325 -- inaccuracy added by hip firing.
SWEP.MoveDispersion = 170

SWEP.Primary.Ammo = "pistol" -- what ammo type the gun uses
SWEP.MagID = "mk201" -- the magazine pool this gun draws from

SWEP.ShootVol = 110 -- volume of shoot sound
SWEP.ShootPitch = 95 -- pitch of shoot sound

SWEP.FirstShootSound = "weapons/arccw/dmi_gunsdefense_2/10mm_smg1.wav"
SWEP.ShootSound = "weapons/arccw/dmi_gunsdefense_2/10mm_smg2.wav", "weapons/arccw/dmi_gunsdefense_2/10mm_smg3.wav"
SWEP.ShootSoundSilenced = "weapons/arccw_fml/fas1_suppr/commando9.wav"
SWEP.DistantShootSound = "weapons/arccw/m4a1/m4a1_us_distant_03.wav"

SWEP.MuzzleEffect = "muzzleflash_1"
SWEP.ShellModel = "models/shells/shell_9mm.mdl"
SWEP.ShellPitch = 95
SWEP.ShellScale = 1.5

SWEP.MuzzleEffectAttachment = 1 -- which attachment to put the muzzle on
SWEP.CaseEffectAttachment = 2 -- which attachment to put the case effect on

SWEP.SpeedMult = 0.95
SWEP.SightedSpeedMult = 0.85
SWEP.SightTime = 0.25

SWEP.BulletBones = { -- the bone that represents bullets in gun/mag
    -- [0] = "bulletchamber",
    -- [1] = "bullet1"
}

SWEP.ProceduralRegularFire = false
SWEP.ProceduralIronFire = false

SWEP.CaseBones = {}

SWEP.IronSightStruct = {
    Pos = Vector(-3.355, -6, 0.43),
    Ang = Angle(-0.144, 0.029, 0),
    Magnification = 1.1,
    SwitchToSound = "", -- sound that plays when switching to this sight
}

SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "rpg"
SWEP.HoldtypeSights = "rpg"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0.5, 1, 0.25)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(8, -2, -4.011)
SWEP.HolsterAng = Angle(1.898, 54.613, -10.113)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.BarrelLength = 25

SWEP.ExtraSightDist = 5

SWEP.AttachmentElements = {
    ["ammo_bullet"] = {
        ExcludeFlags = {"perk_cmags"},
    },
    ["nois"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
        WMBodygroups = {{ind = 1, bg = 1}},
    },
	["extendedmag"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
        WMBodygroups = {{ind = 3, bg = 1}},
    },
    ["stock_sturdy"] = {
        VMBodygroups = {{ind = 2, bg = 0}},
        WMBodygroups = {{ind = 2, bg = 0}},
    },
    ["stock_heavy"] = {
        VMBodygroups = {{ind = 2, bg = 0}},
        WMBodygroups = {{ind = 2, bg = 0}},
    },
    ["stock_light"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
        WMBodygroups = {{ind = 2, bg = 1}},
    },
    ["stock_skeleton"] = {
        VMBodygroups = {{ind = 2, bg = 0}},
        WMBodygroups = {{ind = 2, bg = 0}},
    },
	["stock_strafe"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
        WMBodygroups = {{ind = 2, bg = 1}},
    },
    ["stock_jinc_polimeric"] = {
        VMBodygroups = {{ind = 2, bg = 0}},
        WMBodygroups = {{ind = 2, bg = 0}},
    },
    ["stock_bahkins"] = {
        VMBodygroups = {{ind = 2, bg = 0}},
        WMBodygroups = {{ind = 2, bg = 0}},
    },
    ["bkrail"] = {
     VMElements = {
        {
            Model = "models/weapons/arccw/atts/backup_rail.mdl",
            Bone = "Weapon_Main",
            Offset = {
                pos = Vector(0, -4.5, 9),
                ang = Angle(180, 90, 180),
           },
		 },
      }
    },		
}

SWEP.RejectAttachments = {
    ["perk_fastreload"] = true,
    ["ubgl"] = true	
}

SWEP.Attachments = {
    {
        PrintName = "Optic", -- print name
        DefaultAttName = "Iron Sights",
        Slot = {"optic", "optic_lp"}, -- what kind of attachments can fit here, can be string or table
        Bone = "Weapon_Main", -- relevant bone any attachments will be mostly referring to
        Offset = {
            vpos = Vector(0.02, -4.3, 4), -- offset that the attachment will be relative to the bone
            vang = Angle(90, 0, -90),
            wpos = Vector(5.36, 0.85, -5.4),
            wang = Angle(-10, 0, 180)
        },
        InstalledEles = {"nois"},
    },
    {
        PrintName = "Backup Optic", -- print name
        Slot = {"optic_lp"}, -- what kind of attachments can fit here, can be string or table
        Bone = "Weapon_Main", -- relevant bone any attachments will be mostly referring to
        Offset = {
            vpos = Vector(-0.65, -4.9, 9), -- offset that the attachment will be relative to the bone
            vang = Angle(90, 0, -45),
            wpos = Vector(12.2, 0.69, -6.25),
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
            vpos = Vector(0, -3, 13.5),
            vang = Angle(90, 0, -90),
            wpos = Vector(15.2, 0.85, -5.76),
            wang = Angle(-9.79, 0, 180)
        },
    },	
    {
        PrintName = "Underbarrel",
        Slot = {"foregrip", "ubgl", "bipod","style_pistol"},
        Bone = "Weapon_Main",
        Offset = {
            vang = Angle(90,0, -90),
            wang = Angle(-10.216, 0, 180),
            vpos = Vector(0, -2, 12),
            wpos = Vector(14, 0.832, -4.5),
        },		
    },
    {
        PrintName = "Tactical",
        Slot = "tac",
        Bone = "Weapon_Main",
        Offset = {
            vpos = Vector(-1, -3, 10), -- offset that the attachment will be relative to the bone
            vang = Angle(90, 0, 180),
            wpos = Vector(12, -0.253, -5),
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
            vpos = Vector(0.4, -2, 6),
            vang = Angle(90, 0, -90),
            wpos = Vector(8.4, 1.2, -3.65),
            wang = Angle(-9, 0, 180)
        },
		FreeSlot = true,
    },		
}

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
        Time = 1
    },
    ["draw"] = {
        Source = "draw",
        Time = 35/60,
        SoundTable = {{s = "weapons/arccw/aug/aug_draw.wav", t = 0}},
        LHIK = true,
        LHIKIn = 1,
        LHIKOut = 1,
    },
    ["ready"] = {
        Source = "deploy",
        Time = 70/60,
        SoundTable = {
        SoundTable = {{s = "weapons/arccw/aug/aug_draw.wav", t = 0}},
		},		
        LHIK = true,
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
        Time = 130/60,	
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
		Checkpoints = {37, 58, 75, 92, 119, 124},	
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.4,
    },
    ["reload_empty"] = {
        Source = "dry",
        Time = 185/60,		
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
		Checkpoints = {37, 58, 75, 92, 119, 124},	
        LHIK = true,
        LHIKIn = 0.3,
        LHIKOut = 0.6,
    },
    ["reload_soh"] = {
        Source = "soh_wet",
        Time = 95/60,	
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
		Checkpoints = {37, 58, 75, 92, 119, 124},	
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.3,
    },
    ["reload_empty_soh"] = {
        Source = "soh_dry",
        Time = 120/60,		
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
		Checkpoints = {37, 58, 75, 92, 119, 124},	
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.3,
    },	
}