SWEP.Base = "arccw_base"
SWEP.Spawnable = true -- this obviously has to be set to true
SWEP.Category = "ArcCW - FA:S1" -- edit this if you like
SWEP.AdminOnly = false

SWEP.PrintName = "RO-14"
SWEP.TrueName = "M870"
SWEP.Trivia_Class = "Shotgun"
SWEP.Trivia_Desc = "Pump-action shotgun widely used by the public for sport shooting, hunting, and self-defense and used by law enforcement and military organizations worldwide."
SWEP.Trivia_Manufacturer = "Remington Arms"
SWEP.Trivia_Calibre = "12 Gauge"
SWEP.Trivia_Country = "United States"
SWEP.Trivia_Year = "1950"

if GetConVar("arccw_truenames"):GetBool() then SWEP.PrintName = SWEP.TrueName end

SWEP.Slot = 2

SWEP.UseHands = true

SWEP.NPCWeaponType = "weapon_shotgun"
SWEP.NPCWeight = 200

SWEP.CrouchPos = Vector(-1, -1, -0.5)
SWEP.CrouchAng = Angle(0, 0, -20)

SWEP.ViewModel = "models/weapons/arccw/fml/fas1/c_m870.mdl"
SWEP.WorldModel = "models/weapons/arccw/fml/fas1/w_m870.mdl"
SWEP.ViewModelFOV = 70

SWEP.Damage = 15
SWEP.DamageMin = 2 -- damage done at maximum range
SWEP.Range = 14 -- in METRES
SWEP.RangeMin = 0 -- in METRES
SWEP.Penetration = 1
SWEP.DamageType = DMG_BUCKSHOT
SWEP.ShootEntity = nil -- entity to fire, if any
SWEP.MuzzleVelocity = 150 -- projectile or phys bullet muzzle velocity
-- IN M/S

SWEP.TracerNum = 1 -- tracer every X
SWEP.TracerCol = Color(255, 25, 25)
SWEP.TracerWidth = 3

SWEP.ChamberSize = 1 -- how many rounds can be chambered.
SWEP.Primary.ClipSize = 6 -- DefaultClip is automatically set.
SWEP.ExtendedClipSize = 8
SWEP.ReducedClipSize = 4

SWEP.Recoil = 7
SWEP.RecoilSide = 1
SWEP.MaxRecoilBlowback = 0.8

SWEP.ShotgunReload = true
SWEP.ManualAction = true

SWEP.Delay = 60 / 220 -- 60 / RPM.
SWEP.Num = 11
SWEP.RunawayBurst = false
SWEP.Firemodes = {
    {
        PrintName = "PUMP",
        Mode = 1,
    },
    {
        Mode = 0
    }
}

SWEP.NPCWeaponType = "weapon_shotgun"
SWEP.NPCWeight = 200

SWEP.AccuracyMOA = 70 -- accuracy in Minutes of Angle. There are 60 MOA in a degree.
SWEP.HipDispersion = 220 -- inaccuracy added by hip firing.
SWEP.MoveDispersion = 200

SWEP.NoLastCycle = true

SWEP.Primary.Ammo = "buckshot" -- what ammo type the gun uses

SWEP.ShootVol = 120 -- volume of shoot sound
SWEP.ShootPitch = 100 -- pitch of shoot sound

SWEP.ShootSound = "weapons/arccw_fml/shotgun_rem870/rem870_fire1.wav"
SWEP.ShootSound = "weapons/arccw_fml/shotgun_rem870/rem870_fire2.wav", "weapons/arccw_fml/shotgun_rem870/rem870_fire3.wav", "weapons/arccw_fml/shotgun_rem870/rem870_fire4.wav","weapons/arccw_fml/shotgun_rem870/rem870_fire5.wav"
SWEP.ShootSoundSilenced = "weapons/arccw_fml/fas1_suppr/m870.wav"
SWEP.DistantShootSound = "weapons/arccw/sawedoff/sawedoff-1-distant.wav"

SWEP.MuzzleEffect = "muzzleflash_shotgun"
SWEP.ShellModel = "models/shells/shell_12gauge.mdl"
SWEP.ShellPitch = 100
SWEP.ShellSounds = ArcCW.ShotgunShellSoundsTable
SWEP.ShellScale = 1.5

SWEP.MuzzleEffectAttachment = 1 -- which attachment to put the muzzle on
SWEP.CaseEffectAttachment = 2 -- which attachment to put the case effect on

SWEP.SpeedMult = 0.95
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.225

SWEP.BulletBones = { -- the bone that represents bullets in gun/mag
    -- [0] = "bulletchamber",
    -- [1] = "bullet1"
}

SWEP.ProceduralRegularFire = false
SWEP.ProceduralIronFire = false

SWEP.CaseBones = {}

SWEP.IronSightStruct = {
    Pos = Vector(-3.641, 0, -0.48),
    Ang = Angle(0, 0, 0),
    Magnification = 1.1,
    SwitchToSound = "", -- sound that plays when switching to this sight
}


SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "shotgun"
SWEP.HoldtypeSights = "ar2"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN

SWEP.ActivePos = Vector(0, 2, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(10, -6, -4.011)
SWEP.HolsterAng = Angle(1.898, 54.613, -10.113)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.AttachmentElements = {
    ["mag_cum"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
        WMBodygroups = {{ind = 1, bg = 1}},
    },
}


SWEP.ExtraSightDist = 5

SWEP.Attachments = {
    {
        PrintName = "Optic", -- print name
        DefaultAttName = "Iron Sights",
        Slot = {"optic", "optic_lp"}, -- what kind of attachments can fit here, can be string or table
        Bone = "Weapon_Main", -- relevant bone any attachments will be mostly referring to
        Offset = {
            vpos = Vector(0, -2.4, -4.597), -- offset that the attachment will be relative to the bone
            vang = Angle(90, 0, -90),
            wpos = Vector(12, 0.5, -5.8),
            wang = Angle(-9.738, 0, 180)
        },
        CorrectivePos = Vector(0, 0, 0),
        CorrectiveAng = Angle(0, 0, 0),
        InstalledEles = {"mount"}
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "Standard Muzzle",
        Slot = "muzzle_shotgun",
        Bone = "Weapon_Main",
        Offset = {
            vpos = Vector(0.071, -1.3, 20.5),
            vang = Angle(90, 0, -90),
            wpos = Vector(35, 0.782, -9),
            wang = Angle(-9.79, 0, 180)
        },
    },
    {
        PrintName = "Underbarrel",
        Slot =  {"foregrip"},
        Bone = "Weapon_Pump",
        Offset = {
            vang = Angle(90,0, -90),
            wpos = Vector(18.329, 0.602, -4.153),
            wang = Angle(-10.216, 0, 180)
        },
        SlideAmount = {
            vmin = Vector(0, 0, -4),
            vmax = Vector(0, 0, 0),
            wmin = Vector(20, 0.832, -5),
            wmax = Vector(20, 0.832, -5),
        },	
    },
    {
        PrintName = "Tactical",
        Slot = "tac",
        Bone = "Weapon_Main",
        Offset = {
            vpos = Vector(-0.2, -1.2, 5), -- offset that the attachment will be relative to the bone
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
        Slot = {"ammo_shotgun"}
    },	
    {
        PrintName = "Perk",
        Slot = {"perk", "perk_fas_mag_fed", "perk_fas_shotgun"}
    },
    {
        PrintName = "Charm",
        DefaultAttName = "None",
        Slot = {"fml_charm", "charm"},
        Bone = "Weapon_Main",
        Offset = {
            vpos = Vector(0.8, -1, -5),
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

-- draw
-- holster
-- reload
-- fire
-- cycle (for bolt actions)
-- append _empty for empty variation

SWEP.Animations = {
    ["draw"] = {
        Source = "draw",
        Time = 30/60,
        LHIK = false,
        SoundTable = {{s = "weapons/arccw/sawedoff/sawedoff_draw.wav", t = 0}},
    },
    ["ready"] = {
        Source = "deploy",
        Time = 40/60,
        LHIK = false,
    },
    ["fire"] = {
        Source = {"fire"},
        Time = 30/60,
    },
    ["slam"] = {
        Time = 40/60,	
        Source = "slam",
        ShellEjectAt = 2/60,
    },
    ["cycle"] = {
        Source = {"pump", "pump2"},
        Time = 50/60,
        ShellEjectAt = 5/60,
    },
    ["sgreload_start"] = {
        Source = "reload_start",
        Time = 25/60,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0,
    },
    ["sgreload_start_empty"] = {
        Source = "reload_empty_start",
        Time = 120/60,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        ShellEjectAt = 5/60,		
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0,
    },
    ["sgreload_insert"] = {
        Source = "reload_shell",
        Time = 40/60,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        TPAnimStartTime = 0.3,
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 0,
    },
    ["sgreload_finish"] = {
        Source = "reload_end",
        Time = 35/60,
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 0.4,
    },
    ["reload"] = {
        Source = "mag_fed_wet",
        Time = 130/60,	
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {20, 39},		
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.4,
    },
    ["reload_empty"] = {
        Source = "mag_fed_dry",
        Time = 185/60,		
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {20, 39},		
        ShellEjectAt = 130/60,		
        LHIK = true,
        LHIKIn = 0.3,
        LHIKOut = 0.6,
    },
}