SWEP.Base = "arccw_base"
SWEP.Spawnable = true -- this obviously has to be set to true
SWEP.Category = "ArcCW - FA:S1" -- edit this if you like
SWEP.AdminOnly = false

SWEP.PrintName = "SMG-5"
SWEP.TrueName = "MP5"
SWEP.Trivia_Class = "Submachine Gun"
SWEP.Trivia_Desc = "With over 100 variants of the MP5, it's one of the most widely used submachine guns in the world. Can be modified to use an integral suppressor or a modified PDW system"
SWEP.Trivia_Manufacturer = "Heckler & Koch"
SWEP.Trivia_Calibre = "9×19mm Para"
SWEP.Trivia_Country = "(West) Germany"
SWEP.Trivia_Year = "1966"

if GetConVar("arccw_truenames"):GetBool() then SWEP.PrintName = SWEP.TrueName end

SWEP.Slot = 2

SWEP.NPCWeaponType = "weapon_smg1"
SWEP.NPCWeight = 150

SWEP.DefaultBodygroups = "0000000000"

SWEP.UseHands = true

SWEP.ViewModel = "models/weapons/arccw/fml/fas1/c_mp5.mdl"
SWEP.WorldModel = "models/weapons/arccw/fml/fas1/w_mp5.mdl"
SWEP.ViewModelFOV = 70

SWEP.CrouchPos = Vector(-5.8, 2, -0.5)
SWEP.CrouchAng = Angle(0, 0, -45)

SWEP.Damage = 27
SWEP.DamageMin = 21 -- damage done at maximum range
SWEP.Range = 30 -- in METRES
SWEP.Penetration = 4
SWEP.DamageType = DMG_BULLET
SWEP.ShootEntity = nil -- entity to fire, if any
SWEP.MuzzleVelocity = 430 -- projectile or phys bullet muzzle velocity
-- IN M/S

SWEP.CanFireUnderwater = false

SWEP.TracerNum = 1 -- tracer every X
SWEP.TracerCol = Color(255, 25, 25)
SWEP.TracerWidth = 3

SWEP.ChamberSize = 1 -- how many rounds can be chambered.
SWEP.Primary.ClipSize = 30 -- DefaultClip is automatically set.
SWEP.ExtendedClipSize = 45
SWEP.ReducedClipSize = 20

SWEP.Recoil = 0.35
SWEP.RecoilSide = 0.3
SWEP.RecoilRise = 0.2

SWEP.Delay = 60 / 800 -- 60 / RPM.
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

SWEP.AccuracyMOA = 9 -- accuracy in Minutes of Angle. There are 60 MOA in a degree.
SWEP.HipDispersion = 170 -- inaccuracy added by hip firing.
SWEP.MoveDispersion = 200

SWEP.Primary.Ammo = "pistol" -- what ammo type the gun uses
SWEP.MagID = "mk201" -- the magazine pool this gun draws from

SWEP.ShootVol = 100 -- volume of shoot sound
SWEP.ShootPitch = 100 -- pitch of shoot sound

SWEP.FirstShootSound = "weapons/arccw_fml/sub_mp5/mp5_fire1.wav"
SWEP.ShootSound = "weapons/arccw_fml/sub_mp5/mp5_fire2.wav", "weapons/arccw_fml/sub_mp5/mp5_fire3.wav", "weapons/arccw_fml/sub_mp5/mp5_fire4.wav","weapons/arccw_fml/sub_mp5/mp5_fire5.wav"
SWEP.ShootSoundSilenced = "weapons/arccw_fml/fas1_suppr/mp5.wav"
SWEP.DistantShootSound = "weapons/arccw/Weapon_Rotate/Weapon_Rotate-1-distant.wav"

SWEP.MuzzleEffect = "muzzleflash_1"
SWEP.ShellModel = "models/shells/shell_9mm.mdl"
SWEP.ShellScale = 1.5

SWEP.MuzzleEffectAttachment = 1 -- which attachment to put the muzzle on
SWEP.CaseEffectAttachment = 2 -- which attachment to put the case effect on

SWEP.SightTime = 0.235

SWEP.SpeedMult = 0.8
SWEP.SightedSpeedMult = 0.775

SWEP.BarrelLength = 24

SWEP.BulletBones = { -- the bone that represents bullets in gun/mag
    -- [0] = "bulletchamber",
    -- [1] = "bullet1"
}

SWEP.ProceduralRegularFire = false
SWEP.ProceduralIronFire = false

SWEP.CaseBones = {}

SWEP.IronSightStruct = {
    Pos = Vector(-3.481, -4, 0.213),
    Ang = Angle(1.329, 0, 0),
    Magnification = 1.1,
    SwitchToSound = "", -- sound that plays when switching to this sight
}

SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0, 4, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(8, -2, -0.011)
SWEP.HolsterAng = Angle(-12.898, 48.613, -2.113)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.ExtraSightDist = 3

SWEP.RejectAttachments = {
    ["perk_fastreload"] = true	
}

SWEP.AttachmentElements = {
    ["reducedmag"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
        WMBodygroups = {{ind = 3, bg = 1}},		
    },
    ["mp5sd"] = {
        VMBodygroups = {{ind = 2, bg = 2}},
        WMBodygroups = {{ind = 2, bg = 2}},		
		NameChange = "SMG-5 SD",
		TrueNameChange = "MP5SD",					
},
    ["stock_re"] = {
        VMBodygroups = {{ind = 4, bg = 1}},
		WMBodygroups = {{ind = 4, bg = 1}},				
},
    ["kurz_cum"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
        WMBodygroups = {{ind = 2, bg = 1}},
		NameChange = "SMG-5 Kurz",
		TrueNameChange = "MP5K",				
		AttPosMods = {
			[3] = {
					vpos = Vector(0, -4.1, 14),
					wpos = Vector(16, 0.782, -5.8),
			},			
		},		
		Override_HolsterPos = Vector(2.276, -1.167, -8.44),
		Override_HolsterAng = Angle(30.833, 1.792, -1.269),	
},
    ["noch"] = {		
        VMBodygroups = {{ind = 1, bg = 1}},
        WMBodygroups = {{ind = 1, bg = 1}},
    },	
}

SWEP.Attachments = {
    {
        Hidden = true,
        Slot = "perk_fas"
    },
    {
        PrintName = "Optic", -- print name
        DefaultAttName = "Iron Sights",
        Slot = {"optic_lp","optic"}, -- what kind of attachments can fit here, can be string or table
        Bone = "Weapon_Rotate", -- relevant bone any attachments will be mostly referring to
        Offset = {
            vpos = Vector(0, -6, 3), -- offset that the attachment will be relative to the bone
            vang = Angle(90, 0, -90),
            wpos = Vector(6, 0.739, -5.5),
            wang = Angle(-10, 0, 180)
        },
        InstalledEles = {"noch"},
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "Standard Muzzle",
        Slot = "muzzle",
        Bone = "Weapon_Rotate",
        Offset = {
            vpos = Vector(0, -4.1, 17),
            vang = Angle(90, 0, -90),
            wpos = Vector(18, 0.782, -6.3),
            wang = Angle(-9.79, 0, 180)
        },
        MergeSlots = {12},		
    },
    {
        PrintName = "Underbarrel",
        Bone = "Weapon_Rotate",
        Slot = {"foregrip", "style_pistol", "ubgl", "bipod"},		
        Offset = {
            vpos = Vector(0, -3, 10),
            vang = Angle(90,0, -90),
            wpos = Vector(10, 0.602, -2.2),
            wang = Angle(-10.216, 0, 180)
        },		
        SlideAmount = {
            vmin = Vector(0, -3.2, 9.3),
            vmax = Vector(0, -4, 15),
            wmin = Vector(15, 0.602, -5.5),
            wmax = Vector(15, 0.602, -5.5),
        },	
        MergeSlots = {13},			
    },
    {
        PrintName = "Tactical",
        Slot = "tac",
        Bone = "Weapon_Rotate",
        Offset = {
            vpos = Vector(-1, -3.5, 5), -- offset that the attachment will be relative to the bone
            vang = Angle(90, 0, 180),
            wpos = Vector(8, -0.253, -4),
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
        InstalledEles = {"stock_re"},		
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
        Slot = {"perk"},
        MergeSlots = {1},			
    },
    {
        PrintName = "Charm",
        DefaultAttName = "None",
        Slot = {"fml_charm", "charm"},
        Bone = "Weapon_Rotate",
        Offset = {
            vpos = Vector(0.7, -4.2, 5),
            vang = Angle(90, 0, -90),
            wpos = Vector(7, 1.2, -4),
            wang = Angle(-9, 0, 180)
        },
		FreeSlot = true,
    },	
    {
        Hidden = true,
        Slot = "fas1_mp5sd",
        ExcludeFlags = {"mp5k"},		
    },	
    {
        Hidden = true,
        Bone = "Weapon_Rotate",
        Slot = {"fas1_mp5k"},		
        Offset = {
            vpos = Vector(0, -3, 10),
            vang = Angle(90,0, -90),
            wpos = Vector(10, 0.602, -2.2),
            wang = Angle(-10.216, 0, 180)
        },		
        SlideAmount = {
            vmin = Vector(0, -3.2, 9.3),
            vmax = Vector(0, -4, 15),
            wmin = Vector(10, 0.602, -2.2),
            wmax = Vector(10, 0.602, -2.2),
        },	
		GivesFlags = {"mp5k"} 		
    },	
}

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
        Time = 1,
    },
    ["ready"] = {
        Source = "deploy",
        LHIK = true,
        LHIKIn = 0.2,
        LHIKOut = 0.5,
    },
    ["draw"] = {
        Source = "draw",
        Time = 30/60,
        LHIK = true,
        LHIKIn = 1,
        LHIKOut = 1,		
        SoundTable = {
            {
            s = "weapons/arccw/usp/usp_draw.wav",
            t = 0
            }
        },
    },
    ["fire"] = {
        Source = "fire",
        Time = 20/60,
        ShellEjectAt = 0,
    },
    ["fire_iron"] = {
        Source = "iron",
        Time = 20/60,
        ShellEjectAt = 0,
    },
    ["reload"] = {
        Source = "wet",
        Time = 165/60,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        Checkpoints = {36, 57, 77},
        FrameRate = 60,
        LHIK = true,
        LHIKIn = 0.2,
        LHIKOut = 0.3,
    },
    ["reload_empty"] = {
        Source = "dry",
        Time = 205/60,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        Checkpoints = {36, 57, 77, 88},
        FrameRate = 60,
        LHIK = true,
        LHIKIn = 0.1,
        LHIKOut = 0.25,
    },
    ["reload_soh"] = {
        Source = "wet_soh",
        Time = 120/60,	
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {24, 42, 59, 71, 89},
        FrameRate = 37,
        LHIK = true,
        LHIKIn = 0.2,
        LHIKOut = 0.3,
    },
    ["reload_empty_soh"] = {
        Source = "dry_soh",
        Time = 165/60,		
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {24, 42, 59, 71, 89},
        FrameRate = 37,
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.3,
    },	
    ["reload_empty_kurz_soh"] = {
        Source = "dry_kurz_soh",
        Time = 150/60,		
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {24, 42, 59, 71, 89},
        FrameRate = 37,
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.5,
    },	
    ["reload_kurz_soh"] = {
        Source = "wet_soh",
        Time = 100/60,	
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {24, 42, 59, 71, 89},
        FrameRate = 37,
        LHIK = true,
        LHIKIn = 0.2,
        LHIKOut = 0.4,
    },	
    ["reload_kurz_empty"] = {
        Source = "dry_kurz",
        Time = 185/60,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        Checkpoints = {36, 57, 77, 88},
        FrameRate = 60,
        LHIK = true,
        LHIKIn = 0.1,
        LHIKOut = 0.5,
    },	
    ["reload_kurz"] = {
        Source = "wet",
        Time = 150/60,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        Checkpoints = {36, 57, 77},
        FrameRate = 60,
        LHIK = true,
        LHIKIn = 0.2,
        LHIKOut = 0.3,
    },	
}