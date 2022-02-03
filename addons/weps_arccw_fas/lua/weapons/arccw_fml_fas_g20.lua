SWEP.Base = "arccw_base"
SWEP.Spawnable = true -- this obviously has to be set to true
SWEP.Category = "ArcCW - FA:S1" -- edit this if you like
SWEP.AdminOnly = false

SWEP.PrintName = "X20"
SWEP.TrueName = "Glock 20"
SWEP.Trivia_Class = "Pistol"
SWEP.Trivia_Desc = "Polymer frame pistol, popular firearms among civilians for recreational and competition shooting, home- and self-defense, and concealed or open carry."
SWEP.Trivia_Manufacturer = "Glock G.M.B.H."
SWEP.Trivia_Calibre = "9x19mm Para"
SWEP.Trivia_Country = "Austria"
SWEP.Trivia_Year = "1982"

SWEP.Slot = 1

SWEP.CrouchPos = Vector(-4.5, 3, -1)
SWEP.CrouchAng = Angle(0, 0, -30)

SWEP.NPCWeaponType = "weapon_pistol"
SWEP.NPCWeight = 200

if GetConVar("arccw_truenames"):GetBool() then SWEP.PrintName = SWEP.TrueName end

SWEP.UseHands = true

SWEP.ViewModel = "models/weapons/arccw/fml/fas1/c_g20.mdl"
SWEP.WorldModel = "models/weapons/arccw/fml/fas1/w_g20.mdl"
SWEP.ViewModelFOV = 70

SWEP.Damage = 26
SWEP.DamageMin = 17 -- damage done at maximum range
SWEP.Range = 45 -- in METRES
SWEP.Penetration = 3
SWEP.DamageType = DMG_BULLET
SWEP.ShootEntity = nil -- entity to fire, if any
SWEP.MuzzleVelocity = 350 -- projectile or phys bullet muzzle velocity
-- IN M/S

SWEP.CanFireUnderwater = false

SWEP.TracerNum = 1 -- tracer every X
SWEP.TracerCol = Color(255, 25, 25)
SWEP.TracerWidth = 3

SWEP.ChamberSize = 1 -- how many rounds can be chambered.
SWEP.Primary.ClipSize = 15 -- DefaultClip is automatically set.
SWEP.ExtendedClipSize = 30
SWEP.ReducedClipSize = 8

SWEP.Recoil = 0.5
SWEP.RecoilSide = 0.15
SWEP.RecoilRise = 1.5
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

SWEP.AccuracyMOA = 11 -- accuracy in Minutes of Angle. There are 60 MOA in a degree.
SWEP.HipDispersion = 200 -- inaccuracy added by hip firing.
SWEP.MoveDispersion = 300

SWEP.Primary.Ammo = "pistol" -- what ammo type the gun uses
SWEP.MagID = "ppa" -- the magazine pool this gun draws from

SWEP.ShootVol = 110 -- volume of shoot sound
SWEP.ShootPitch = 100 -- pitch of shoot sound

SWEP.ShootSound = "weapons/arccw_fml/pistol_glock20/glock20_fire1.wav"
SWEP.ShootSound = "weapons/arccw_fml/pistol_glock20/glock20_fire2.wav", "weapons/arccw_fml/pistol_glock20/glock20_fire3.wav", "weapons/arccw_fml/pistol_glock20/glock20_fire4.wav","weapons/arccw_fml/pistol_glock20/glock20_fire5.wav"
SWEP.ShootSoundSilenced = "weapons/arccw_fml/fas1_suppr/glock20.wav"
SWEP.DistantShootSound = "weapons/arccw/glock18/glock18-1-distant.wav"

SWEP.MuzzleEffect = "muzzleflash_pistol"
SWEP.ShellModel = "models/shells/shell_9mm.mdl"
SWEP.ShellScale = 1.5

SWEP.MuzzleEffectAttachment = 1 -- which attachment to put the muzzle on
SWEP.CaseEffectAttachment = 2 -- which attachment to put the case effect on

SWEP.SightTime = 0.2

SWEP.SpeedMult = 1
SWEP.SightedSpeedMult = 0.75

SWEP.BarrelLength = 18

SWEP.BulletBones = { -- the bone that represents bullets in gun/mag
    -- [0] = "bulletchamber",
    -- [1] = "bullet1"
}

SWEP.ProceduralRegularFire = false
SWEP.ProceduralIronFire = false

SWEP.CaseBones = {}

SWEP.IronSightStruct = {
    Pos = Vector(-2.662, 12.5, 0.119),
    Ang = Angle(0, 0, 0),
    Magnification = 1.1,
    SwitchToSound = "", -- sound that plays when switching to this sight
}

SWEP.HoldtypeHolstered = "normal"
SWEP.HoldtypeActive = "pistol"
SWEP.HoldtypeSights = "revolver"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL

SWEP.ActivePos = Vector(0.2, 4, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(2, -1.5, -5)
SWEP.HolsterAng = Angle(30.833, 1.792, -1.269)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.ExtraSightDist = 2

SWEP.RejectAttachments = {
    ["perk_fastreload"] = true	
}

SWEP.AttachmentElements = {
    ["roni_conv"] = {
		NameChange = "Roni X20",
		TrueNameChange = "Roni Glock 20",	
		Override_ActivePos = Vector(0, 3, -2),
		Override_ActiveAng = Angle(0, 0, 0),			
        Override_IronSightStruct = {
			Pos = Vector(-2.662, -1.5, -3),
			Ang = Angle(0.349, 0, 0),
            Magnification = 1.1,
        },				
		AttPosMods = {
			[1] = {
					bone = "deagle",			
					vpos = Vector(0, -3, 1),
					wpos = Vector(4.762, 0.832, -5.5),
			},
			[12] = {
					bone = "deagle",			
					vpos = Vector(0, -3, 1),
					wpos = Vector(4.762, 0.832, -5.5),
			},			
			[2] = {
            vpos = Vector(0, -3.2, 12),
			}				
		},
	
},
    ["stock"] = {
        VMElements = {
            {
                Model = "models/weapons/arccw/atts/stock_fab.mdl",
                Bone = "deagle",
                Offset = {
                    pos = Vector(0, 2, -1),
                    ang = Angle(90 , 0, -90)
                }
            }
        },
        WMElements = {
            {
                Model = "models/weapons/arccw/atts/stock_fab.mdl",
                Offset = {
                    pos = Vector(0, 1, 0),
                    ang = Angle(0, -4.211, 0)
                }
            }
        }
    }
}

SWEP.Attachments = {
    {
        PrintName = "Optic", -- print name
        DefaultAttName = "Iron Sights",
        Slot = "optic_lp", -- what kind of attachments can fit here, can be string or table
        Bone = "slide", -- relevant bone any attachments will be mostly referring to
        Offset = {
            vpos = Vector(0, -1, 0.5), -- offset that the attachment will be relative to the bone
            vang = Angle(90, 0, -90),
            wpos = Vector(5.36, 0.739, -3.5),
            wang = Angle(-10, 0, 180)
        },			
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "Standard Muzzle",
        Slot = "muzzle",
        Bone = "deagle",
        Offset = {
            vpos = Vector(0, -3.15, 8),
            vang = Angle(90, 0, -90),
            wpos = Vector(10, 0.782, -3.5),
            wang = Angle(-9.79, 0, 180)
        },
    },
    {
        PrintName = "Underbarrel",
        Slot = {"foregrip_pistol", "style_pistol"},
        Bone = "deagle",
        Offset = {
            vpos = Vector(0, -2.5, 4.2),
            vang = Angle(90,0, -90),
            wpos = Vector(9, 0.602, -2.5),
            wang = Angle(-10.216, 0, 180)
        },			
    },
    {
        PrintName = "Tactical",
        Slot = "tac",
        Bone = "deagle",
        Offset = {
            vpos = Vector(-0.65, -3.5, 5), -- offset that the attachment will be relative to the bone
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
        Bone = "slide",
        Offset = {
            vpos = Vector(0.5, -0.4, 2),
            vang = Angle(90, 0, -90),
            wpos = Vector(8, 1, -3),
            wang = Angle(-9, 0, 180)
        },
		FreeSlot = true,
    },	
    {
		Hidden = true,
        Slot = {"roni_standalone"},
        Bone = "deagle",
        Offset = {
            vpos = Vector(0, -2.5, 4.2),
            vang = Angle(90,0, -90),
            wpos = Vector(9, 0.602, -2.5),
            wang = Angle(-10.216, 0, 180)
        },
		GivesFlags = {"fml_roni_conversion_kit"}		
    },	
    {
		Hidden = true,
        Slot = "optic", -- what kind of attachments can fit here, can be string or table
        Bone = "slide", -- relevant bone any attachments will be mostly referring to
        Offset = {
            vpos = Vector(0, -1, 0.5), -- offset that the attachment will be relative to the bone
            vang = Angle(90, 0, -90),
            wpos = Vector(5.36, 0.739, -3.5),
            wang = Angle(-10, 0, 180)
        },
        RequireFlags = {"fml_roni_conversion_kit"},	
    },	
}


SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
        Time = 1,
    },
    ["idle_empty"] = {
        Source = "idle_empty",
        Time = 1,
    },
    ["ready"] = {
        Source = "deploy",
        Time = 55/60,
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 0.25,
    },
    ["draw_empty"] = {
        Source = "draw_empty",
        Time = 30/60,
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 1,		
        SoundTable = {
            {
            s = "weapons/arccw/usp/usp_draw.wav",
            t = 0
            }
        },
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
        Time = 40/60,
        ShellEjectAt = 0,
    },
    ["fire_empty"] = {
        Source = "fire_empty",
        Time = 40/60,
        ShellEjectAt = 0,
    },
    ["fire_iron"] = {
        Source = "iron",
        Time = 40/60,
        ShellEjectAt = 0,
    },
    ["fire_iron_empty"] = {
        Source = "iron_empty",
        Time = 40/60,
        ShellEjectAt = 0,
    },
    ["reload"] = {
        Source = "wet",
        Time = 115/60,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        Checkpoints = {36, 57, 77},
        FrameRate = 60,
        LHIK = true,
        LHIKIn = 0.2,
        LHIKOut = 0.3,
    },
    ["reload_empty"] = {
        Source = "dry",
        Time = 155/60,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        Checkpoints = {36, 57, 77, 88},
        FrameRate = 60,
        LHIK = true,
        LHIKIn = 0.1,
        LHIKOut = 0.25,
    },
    ["reload_soh"] = {
        Source = "soh_wet",
        Time = 85/60,	
        Checkpoints = {24, 42, 59, 71, 89},
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,		
        FrameRate = 60,
        LHIK = true,
        LHIKIn = 0.2,
        LHIKOut = 0.3,
    },
    ["reload_empty_soh"] = {
        Source = "soh_dry",
        Time = 105/60,		
        Checkpoints = {24, 42, 59, 71, 89},
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,		
        FrameRate = 60,
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.3,
    },		
}