SWEP.Base = "arccw_base"
SWEP.Spawnable = true -- this obviously has to be set to true
SWEP.Category = "ArcCW - FA:S1" -- edit this if you like
SWEP.AdminOnly = false

SWEP.PrintName = "SMG-11"
SWEP.TrueName = "Mac-11"
SWEP.Trivia_Class = "Machine Pistol"
SWEP.Trivia_Desc = "Subcompact machine pistol/submachine gun developed during the 1970s in Powder Springs, Georgia. The weapon is a sub-compact version of the Model 10, and is chambered to fire the smaller .380 ACP round."
SWEP.Trivia_Manufacturer = "Military Armament Corporation"
SWEP.Trivia_Calibre = ".380 ACP"
SWEP.Trivia_Country = "United States"
SWEP.Trivia_Year = "1972"

if GetConVar("arccw_truenames"):GetBool() then SWEP.PrintName = SWEP.TrueName end

SWEP.CrouchPos = Vector(-7, 2, -1)
SWEP.CrouchAng = Angle(0, 0, -30)

SWEP.NPCWeaponType = "weapon_smg1"
SWEP.NPCWeight = 120

SWEP.Slot = 2

SWEP.UseHands = true

SWEP.ViewModel = "models/weapons/arccw/fml/fas1/c_mac11.mdl"
SWEP.WorldModel = "models/weapons/arccw/fml/fas1/w_m11.mdl"
SWEP.ViewModelFOV = 70

SWEP.Damage = 21
SWEP.DamageMin = 12 -- damage done at maximum range
SWEP.Range = 30 -- in METRES
SWEP.Penetration = 2
SWEP.DamageType = DMG_BULLET
SWEP.ShootEntity = nil -- entity to fire, if any
SWEP.MuzzleVelocity = 275 -- projectile or phys bullet muzzle velocity
-- IN M/S

SWEP.CanFireUnderwater = false

SWEP.TracerNum = 1 -- tracer every X
SWEP.TracerCol = Color(255, 25, 25)
SWEP.TracerWidth = 3

SWEP.ChamberSize = 0 -- how many rounds can be chambered.
SWEP.Primary.ClipSize = 20 -- DefaultClip is automatically set.
SWEP.ExtendedClipSize = 30
SWEP.ReducedClipSize = 10

SWEP.Recoil = 0.5
SWEP.RecoilSide = 0.3
SWEP.RecoilRise = 0.55
SWEP.VisualRecoilMult = 0.1

-- does it make sense that the mac-11 fires slow? no, but do i care? also no
SWEP.Delay = 60 / 1050
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

SWEP.AccuracyMOA = 14 -- accuracy in Minutes of Angle. There are 60 MOA in a degree.
SWEP.HipDispersion = 270 -- inaccuracy added by hip firing.
SWEP.MoveDispersion = 240

SWEP.Primary.Ammo = "pistol" -- what ammo type the gun uses
SWEP.MagID = "mk201" -- the magazine pool this gun draws from

SWEP.ShootVol = 100 -- volume of shoot sound
SWEP.ShootPitch = 100 -- pitch of shoot sound

SWEP.FirstShootSound = "weapons/arccw_fml/sub_mac11/mac11_fire1.wav"
SWEP.ShootSound = "weapons/arccw_fml/sub_mac11/mac11_fire2.wav", "weapons/arccw_fml/sub_mac11/mac11_fire3.wav", "weapons/arccw_fml/sub_mac11/mac11_fire4.wav","weapons/arccw_fml/sub_mac11/mac11_fire5.wav"
SWEP.ShootSoundSilenced = "weapons/arccw_fml/fas1_suppr/m11.wav"
SWEP.DistantShootSound = "weapons/arccw/mac10/mac10-1-distant.wav"

SWEP.MuzzleEffect = "muzzleflash_1"
SWEP.ShellModel = "models/shells/shell_9mm.mdl"
SWEP.ShellScale = 1.5

SWEP.MuzzleEffectAttachment = 1 -- which attachment to put the muzzle on
SWEP.CaseEffectAttachment = 2 -- which attachment to put the case effect on

SWEP.SightTime = 0.175

SWEP.SpeedMult = 1
SWEP.SightedSpeedMult = 0.85

SWEP.BarrelLength = 10

SWEP.BulletBones = { -- the bone that represents bullets in gun/mag
    -- [0] = "bulletchamber",
    -- [1] = "bullet1"
}

SWEP.ProceduralRegularFire = false
SWEP.ProceduralIronFire = false

SWEP.CaseBones = {}

SWEP.IronSightStruct = {
    Pos = Vector(-3.737, -3.5, 0.66),
    Ang = Angle(0, 0, 0),
    Magnification = 1.1,
    SwitchToSound = "", -- sound that plays when switching to this sight
}

SWEP.HoldtypeHolstered = "normal"
SWEP.HoldtypeActive = "pistol"
SWEP.HoldtypeSights = "revolver"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0, 2, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(-0.5, -5, -8.44)
SWEP.HolsterAng = Angle(30.833, 1.792, -1.269)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.ExtraSightDist = 3

SWEP.RejectAttachments = {
    ["perk_fastreload"] = true	
}

SWEP.Attachments = {
    {
        PrintName = "Optic", -- print name
        DefaultAttName = "Iron Sights",
        Slot = "optic_lp", -- what kind of attachments can fit here, can be string or table
        Bone = "mac10", -- relevant bone any attachments will be mostly referring to
        Offset = {
            vpos = Vector(0, -4.8, -2), -- offset that the attachment will be relative to the bone
            vang = Angle(90, 0, -90),
            wpos = Vector(5.36, 0.739, -5),
            wang = Angle(-10, 0, 180)
        },
        InstalledEles = {"noch"},
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "Standard Muzzle",
        Slot = "muzzle",
        Bone = "mac10",
        Offset = {
            vpos = Vector(0, -3.25, 7),
            vang = Angle(90, 0, -90),
            wpos = Vector(11, 0.782, -4.15),
            wang = Angle(-9.79, 0, 180)
        },
    },
    {
        PrintName = "Underbarrel",
        Slot = {"foregrip", "style_pistol"},
        Bone = "mac10",
        Offset = {
            vpos = Vector(0, -2, 5),
            vang = Angle(90,0, -90),
            wpos = Vector(10, 0.602, -2.2),
            wang = Angle(-10.216, 0, 180)
        },
    },
    {
        PrintName = "Tactical",
        Slot = "tac",
        Bone = "mac10",
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
        Bone = "mac10",
        Offset = {
            vpos = Vector(0.9, -4, -3),
            vang = Angle(90, 0, -90),
            wpos = Vector(7, 1.2, -4),
            wang = Angle(-9, 0, 180)
        },
		FreeSlot = true,
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
        LHIKIn = 0.2,
        LHIKOut = 0.3,
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
        Time = 20/60,
        ShellEjectAt = 0,
    },
    ["fire_empty"] = {
        Source = "fire_empty",
        Time = 20/60,
        ShellEjectAt = 0,
    },
    ["fire_iron"] = {
        Source = "iron",
        Time = 20/60,
        ShellEjectAt = 0,
    },
    ["fire_iron_empty"] = {
        Source = "iron_empty",
        Time = 20/60,
        ShellEjectAt = 0,
    },
    ["reload"] = {
        Source = "wet",
        Time = 120/60,
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
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {24, 42, 59, 71, 89},
        FrameRate = 37,
        LHIK = true,
        LHIKIn = 0.2,
        LHIKOut = 0.3,
    },
    ["reload_empty_soh"] = {
        Source = "soh_dry",
        Time = 115/60,		
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {24, 42, 59, 71, 89},
        FrameRate = 37,
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.3,
    },		
}