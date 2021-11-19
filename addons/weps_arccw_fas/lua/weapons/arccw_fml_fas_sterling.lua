SWEP.Base = "arccw_base"
SWEP.Spawnable = true -- this obviously has to be set to true
SWEP.Category = "ArcCW - FA:S1" -- edit this if you like
SWEP.AdminOnly = false

SWEP.PrintName = "C1-9mm"
SWEP.TrueName = "Sterling"
SWEP.Trivia_Class = "Submachine Gun"
SWEP.Trivia_Desc = "Hard hitting submachine gun. A successful and reliable design, it remained as standard issue with the British Army until 1994. This version use a special bolt due to the animator's poor researching."
SWEP.Trivia_Manufacturer = "Sterling Armaments Company"
SWEP.Trivia_Calibre = "9x19mm Para"
SWEP.Trivia_Country = "United Kingdom"
SWEP.Trivia_Year = "1953"

SWEP.CrouchPos = Vector(-1, -3, 0.5)
SWEP.CrouchAng = Angle(0, 0, -15)

SWEP.Slot = 2

if GetConVar("arccw_truenames"):GetBool() then SWEP.PrintName = SWEP.TrueName end

SWEP.UseHands = true

SWEP.ViewModel = "models/weapons/arccw/fml/fas1/c_sterling.mdl"
SWEP.WorldModel = "models/weapons/arccw/fml/fas1/w_sterling.mdl"
SWEP.ViewModelFOV = 70

SWEP.DefaultBodygroups = "000000"

SWEP.Damage = 27
SWEP.DamageMin = 14 -- damage done at maximum range
SWEP.Range = 80 -- in METRES
SWEP.Penetration = 2
SWEP.DamageType = DMG_BULLET
SWEP.ShootEntity = nil -- entity to fire, if any
SWEP.MuzzleVelocity = 1000 -- projectile or phys bullet muzzle velocity
-- IN M/S

SWEP.TracerNum = 1 -- tracer every X
SWEP.TracerCol = Color(255, 25, 25)
SWEP.TracerWidth = 3

SWEP.ChamberSize = 0 -- how many rounds can be chambered.
SWEP.Primary.ClipSize = 25 -- DefaultClip is automatically set.
SWEP.ExtendedClipSize = 40
SWEP.ReducedClipSize = 12

SWEP.Recoil = 0.5
SWEP.RecoilSide = 0.08
SWEP.RecoilRise = 0.3
SWEP.VisualRecoilMult = 0.75

SWEP.NPCWeaponType = "weapon_smg1"
SWEP.NPCWeight = 150

SWEP.Delay = 60 / 600 -- 60 / RPM.
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

SWEP.AccuracyMOA = 7 -- accuracy in Minutes of Angle. There are 60 MOA in a degree.
SWEP.HipDispersion = 350 -- inaccuracy added by hip firing.
SWEP.MoveDispersion = 125

SWEP.Primary.Ammo = "pistol" -- what ammo type the gun uses
SWEP.MagID = "mk201" -- the magazine pool this gun draws from

SWEP.ShootVol = 110 -- volume of shoot sound
SWEP.ShootPitch = 95 -- pitch of shoot sound

SWEP.FirstShootSound = "weapons/arccw_fml/sub_sterling/sterling_fire1.wav"
SWEP.ShootSound = "weapons/arccw_fml/sub_sterling/sterling_fire2.wav", "weapons/arccw_fml/sub_sterling/sterling_fire3.wav"
SWEP.ShootSoundSilenced = "weapons/arccw_fml/fas1_suppr/sterling.wav"
SWEP.DistantShootSound = "weapons/arccw/m4a1/m4a1_us_distant_03.wav"

SWEP.MuzzleEffect = "muzzleflash_1"
SWEP.ShellModel = "models/shells/shell_9mm.mdl"
SWEP.ShellPitch = 95
SWEP.ShellScale = 1.5

SWEP.MuzzleEffectAttachment = 1 -- which attachment to put the muzzle on
SWEP.CaseEffectAttachment = 2 -- which attachment to put the case effect on

SWEP.SpeedMult = 0.95
SWEP.SightedSpeedMult = 0.775
SWEP.SightTime = 0.25

SWEP.BulletBones = { -- the bone that represents bullets in gun/mag
    -- [0] = "bulletchamber",
    -- [1] = "bullet1"
}

SWEP.ProceduralRegularFire = false
SWEP.ProceduralIronFire = false

SWEP.CaseBones = {}

SWEP.IronSightStruct = {
    Pos = Vector(-3.715, -6, 2.559),
    Ang = Angle(0.118,0,0),
    Magnification = 1.1,
    SwitchToSound = "", -- sound that plays when switching to this sight
}

SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0, -2, -0.2)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(8, -7, -4.011)
SWEP.HolsterAng = Angle(1.898, 54.613, -10.113)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.BarrelLength = 25

SWEP.ExtraSightDist = 5

SWEP.AttachmentElements = {
    ["noch"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
        WMBodygroups = {},
    },
}

SWEP.RejectAttachments = {
    ["perk_fastreload"] = true	
}

SWEP.Attachments = {
    --[[{
        PrintName = "Optic", -- print name
        DefaultAttName = "Iron Sights",
        Slot = "optic", -- what kind of attachments can fit here, can be string or table
        Bone = "Weapon_Main", -- relevant bone any attachments will be mostly referring to
        Offset = {
            vpos = Vector(0, -3.2, -2), -- offset that the attachment will be relative to the bone
            vang = Angle(90, 0, -90),
            wpos = Vector(6, 0.739, -4.7),
            wang = Angle(-10, 0, 180)
        },
        InstalledEles = {"noch"},
    },]]
    {
        PrintName = "Muzzle",
        DefaultAttName = "Standard Muzzle",
        Slot = "muzzle",
        Bone = "Weapon_Main",
        Offset = {
            vpos = Vector(0, -2.2, 13),
            vang = Angle(90, 0, -90),
            wpos = Vector(17, 0.782, -5.5),
            wang = Angle(-9.79, 0, 180)
        },
    },
    --[[{
        PrintName = "Underbarrel",
        Slot = {"foregrip", "ubgl", "bipod", "style_pistol"},
        Bone = "Weapon_Main",
        Offset = {
            vang = Angle(90,0, -90),
            wpos = Vector(14.329, 0.602, -4.453),
            wang = Angle(-10.216, 0, 180)
        },
        SlideAmount = {
            vmin = Vector(0, -0.3, 8),
            vmax = Vector(0, -0.3, 14),
            wmin = Vector(11, 0.832, -3.5),
            wmax = Vector(11, 0.832, -3.5),
        }
    },
    {
        PrintName = "Tactical",
        Slot = "tac",
        Bone = "Weapon_Main",
        Offset = {
            vpos = Vector(-1, -2, 5), -- offset that the attachment will be relative to the bone
            vang = Angle(90, 0, 180),
            wpos = Vector(15.625, -0.253, -6.298),
            wang = Angle(-8.829, -0.556, 90)
        },
    },]]
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
            vpos = Vector(0.8, -2.3, 2),
            vang = Angle(90, 0, -90),
            wpos = Vector(5, 1, -3),
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
    ["draw"] = {
        Source = "draw",
        Time = 35/60,
        SoundTable = {{s = "weapons/arccw/aug/aug_draw.wav", t = 0}},
        LHIK = true,
        LHIKIn = 1,
        LHIKOut = 1,
    },
    ["draw_empty"] = {
        Source = "draw_empty",
        Time = 35/60,
        SoundTable = {{s = "weapons/arccw/aug/aug_draw.wav", t = 0}},
        LHIK = true,
        LHIKIn = 1,
        LHIKOut = 1,
    },	
    ["ready"] = {
        Source = "deploy",
        Time = 65/60,
        SoundTable = {
        SoundTable = {{s = "weapons/arccw/aug/aug_draw.wav", t = 0}},
		},		
        LHIK = false,
        LHIKIn = 0,
        LHIKOut = 0.25,
    },
    ["fire"] = {
        Source = "fire",
        Time = 30/60,
        ShellEjectAt = 0,
    },
    ["fire_empty"] = {
        Source = "fire_empty",
        Time = 30/60,
        ShellEjectAt = 0,
    },
    ["fire_iron"] = {
        Source = "iron",
        Time = 30/60,
        ShellEjectAt = 0,
    },
    ["fire_iron_empty"] = {
        Source = "iron_empty",
        Time = 30/60,
        ShellEjectAt = 0,
    },
    ["reload"] = {
        Source = "wet",
        Time = 125/60,	
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {24, 42, 59, 71},
        FrameRate = 37,
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.4,
    },
    ["reload_empty"] = {
        Source = "dry",
        Time = 185/60,		
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {24, 42, 59, 71, 89},
        FrameRate = 37,
        LHIK = true,
        LHIKIn = 0.3,
        LHIKOut = 0.3,
    },
    ["reload_soh"] = {
        Source = "soh_wet",
        Time = 95/60,	
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {24, 42, 59, 71, 89},
        FrameRate = 37,
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.3,
    },
    ["reload_empty_soh"] = {
        Source = "soh_dry",
        Time = 140/60,		
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {24, 42, 59, 71, 89},
        FrameRate = 37,
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.3,
    },	
}