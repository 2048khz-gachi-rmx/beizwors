SWEP.Base = "arccw_base"
SWEP.Spawnable = true -- this obviously has to be set to true
SWEP.Category = "ArcCW - FA:S1" -- edit this if you like
SWEP.AdminOnly = false

SWEP.PrintName = "RG33"
SWEP.TrueName = "G3A3"
SWEP.Trivia_Class = "Battle Rifle"
SWEP.Trivia_Desc = "Hard hitting, select-fire battle rifle developed in the 1950s by the German armament manufacturer Heckler & Koch (H&K) in collaboration with the Spanish state-owned design and development agency CETME."
SWEP.Trivia_Manufacturer = "Heckler & Koch"
SWEP.Trivia_Calibre = "7.62x51mm NATO"
SWEP.Trivia_Country = "(West) Germany"
SWEP.Trivia_Year = "1958"

if GetConVar("arccw_truenames"):GetBool() then SWEP.PrintName = SWEP.TrueName end

SWEP.Slot = 2

SWEP.UseHands = true

SWEP.NPCWeaponType = "weapon_ar2"
SWEP.NPCWeight = 130

SWEP.ViewModel = "models/weapons/arccw/fml/fas1/c_g3a3.mdl"
SWEP.WorldModel = "models/weapons/arccw/fml/fas1/w_g3a3.mdl"
SWEP.ViewModelFOV = 70

SWEP.DefaultBodygroups = "000"

SWEP.CrouchPos = Vector(-6.5, 0, 1)
SWEP.CrouchAng = Angle(0, 0, -45)

SWEP.Damage = 58
SWEP.DamageMin = 31 -- damage done at maximum range
SWEP.Range = 90 -- in METRES
SWEP.Penetration = 19
SWEP.DamageType = DMG_BULLET
SWEP.ShootEntity = nil -- entity to fire, if any
SWEP.MuzzleVelocity = 1800 -- projectile or phys bullet muzzle velocity
-- IN M/S

SWEP.TracerNum = 1 -- tracer every X
SWEP.TracerCol = Color(255, 25, 25)
SWEP.TracerWidth = 3

SWEP.ChamberSize = 1 -- how many rounds can be chambered.
SWEP.Primary.ClipSize = 20 -- DefaultClip is automatically set.
SWEP.ExtendedClipSize = 30
SWEP.ReducedClipSize = 10

SWEP.Recoil = 0.8
SWEP.RecoilSide = 0.5
SWEP.RecoilRise = 0.2
SWEP.VisualRecoilMult = 0.5

SWEP.Delay = 60 / 500 -- 60 / RPM.
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

SWEP.AccuracyMOA = 1.2 -- accuracy in Minutes of Angle. There are 60 MOA in a degree.
SWEP.HipDispersion = 400 -- inaccuracy added by hip firing.
SWEP.MoveDispersion = 600

SWEP.Primary.Ammo = "ar2" -- what ammo type the gun uses
SWEP.MagID = "ag63" -- the magazine pool this gun draws from

SWEP.ShootVol = 120 -- volume of shoot sound
SWEP.ShootPitch = 100 -- pitch of shoot sound

SWEP.FirstShootSound = "weapons/arccw_fml/ar_g3a3/g3_fire2.wav"
SWEP.ShootSound = "weapons/arccw_fml/ar_g3a3/g3_fire2.wav", "weapons/arccw_fml/ar_g3a3/g3_fire3.wav", "weapons/arccw_fml/ar_g3a3/g3_fire4.wav","weapons/arccw_fml/ar_g3a3/g3_fire5.wav"
SWEP.DistantShootSound = "weapons/arccw/g3sg1/g3sg1_distant_01.wav"
SWEP.ShootSoundSilenced = "weapons/arccw_fml/fas1_suppr/g3a3.wav"

SWEP.MuzzleEffect = "muzzleflash_1"
SWEP.ShellModel = "models/shells/shell_762nato.mdl"
SWEP.ShellPitch = 90
SWEP.ShellRotate = 180
SWEP.ShellScale = 1.5

SWEP.MuzzleEffectAttachment = 1 -- which attachment to put the muzzle on
SWEP.CaseEffectAttachment = 2 -- which attachment to put the case effect on

SWEP.SpeedMult = 0.8
SWEP.SightedSpeedMult = 0.5
SWEP.SightTime = 0.375

SWEP.BulletBones = { -- the bone that represents bullets in gun/mag
    -- [0] = "bulletchamber",
    -- [1] = "bullet1"
}

SWEP.ProceduralRegularFire = false
SWEP.ProceduralIronFire = false

SWEP.CaseBones = {}

SWEP.IronSightStruct = {
    Pos = Vector(-4.5, -2, 0.8),
    Ang = Angle(0.764, 0, 0),
    Magnification = 1.1,
    SwitchToSound = "", -- sound that plays when switching to this sight
}

SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0, 2, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(8, -2, -4.011)
SWEP.HolsterAng = Angle(1.898, 54.613, -10.113)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.BarrelLength = 35

SWEP.AttachmentElements = {
    ["noch"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
        WMBodygroups = {},
    },
    ["bkrail"] = {	
     VMElements = {
        {
            Model = "models/weapons/arccw/atts/backup_rail.mdl",
              Bone = "v_weapon.g3sg1_Parent",
             Offset = {
                 pos = Vector(0, -7.2, -10),
				 ang = Angle(180, 90, 0),
           },
		 },
      }
    },		
}

SWEP.RejectAttachments = {
    ["perk_fastreload"] = true	
}


SWEP.Attachments = {
    {
        PrintName = "Optic", -- print name
        DefaultAttName = "Iron Sights",
        Slot = {"optic", "optic_sniper"}, -- what kind of attachments can fit here, can be string or table
        Bone = "v_weapon.g3sg1_Parent", -- relevant bone any attachments will be mostly referring to
        Offset = {
            vpos = Vector(0, -7, 0), -- offset that the attachment will be relative to the bone
            vang = Angle(-90, 0, -90),
            wpos = Vector(8, 0.739, -5.5),
            wang = Angle(-10, 0, 180)
        },
        InstalledEles = {"noch"},
		ExtraSightDist = 5	
    },
    {
        PrintName = "Backup Optic", -- print name
        Slot = {"optic_lp"}, -- what kind of attachments can fit here, can be string or table
        Bone = "v_weapon.g3sg1_Parent", -- relevant bone any attachments will be mostly referring to
        Offset = {
            vpos = Vector(0.5, -7.4, -10), -- offset that the attachment will be relative to the bone
            vang = Angle(-90, 0, -45),
            wpos = Vector(15, -0.25, -5.75),
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
        Bone = "v_weapon.g3sg1_Parent",
        Offset = {
            vpos = Vector(0, -5.45, -26.5),
            vang = Angle(-90, 0, -90),
            wpos = Vector(26.648, 0.782, -7.4),
            wang = Angle(-9.79, 0, 180)
        },
    },
    {
        PrintName = "Underbarrel",
        Slot = {"foregrip", "ubgl", "bipod"},
        Bone = "v_weapon.g3sg1_Parent",
        Offset = {
            vang = Angle(-90,0, -90),
            wpos = Vector(14.329, 0.602, -4.453),
            wang = Angle(-10.216, 0, 180)
        },
        SlideAmount = {
            vmin = Vector(0, -4.75, -9.5),
            vmax = Vector(0, -5, -16),
            wmin = Vector(16, 0.832, -5),
            wmax = Vector(16, 0.832, -5),
        },			
    },
    {
        PrintName = "Tactical",
        Slot = "tac",
        Bone = "v_weapon.g3sg1_Parent",
        Offset = {
            vpos = Vector(1, -5.5, -10), -- offset that the attachment will be relative to the bone
            vang = Angle(-90, 0, 180),
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
        Bone = "v_weapon.g3sg1_Parent",
        Offset = {
            vpos = Vector(-0.6, -4.8, -5),
            vang = Angle(-90,0, -90),
            wpos = Vector(8, 1, -3),
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
        Time = 80/60,
        LHIK = true,
        LHIKIn = .5,
        LHIKOut = 1,
    },
    ["fire"] = {
        Source = {"fire"},
        Time = 30/60,
        ShellEjectAt = 0,
    },
    ["fire_iron"] = {
        Source = "fire_iron",
        Time = 30/60,
        ShellEjectAt = 0,
    },
    ["reload"] = {
        Source = "wet",
        Time = 170/60,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {20, 39},
        FrameRate = 30,
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.6,
    },
    ["reload_empty"] = {
        Source = "dry",
        Time = 275/60,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {37, 58, 75, 92, 119, 124},
        FrameRate = 30,
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 1,
    },
    ["reload_soh"] = {
        Source = "soh_wet",
        Time = 135/60,	
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {24, 42, 59, 71, 89},
        FrameRate = 37,
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.5,
    },
    ["reload_empty_soh"] = {
        Source = "soh_dry",
        Time = 180/60,		
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {24, 42, 59, 71, 89},
        FrameRate = 37,
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.5,
    },		
}