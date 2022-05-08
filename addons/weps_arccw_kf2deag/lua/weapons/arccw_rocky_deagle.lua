SWEP.Base = "arccw_base"
SWEP.Spawnable = true -- this obviously has to be set to true
SWEP.Category = "ArcCW - L4D2" -- edit this if you like
SWEP.AdminOnly = false

SWEP.PrintName = "Raven"
SWEP.TrueName = "KF2 Desert Eagle"
SWEP.Trivia_Class = "Pistol"
SWEP.Trivia_Desc = "Some people call it impractical. Sure, you'll never REALLY be able to justify a handgun of this caliber... Unless your job involves breaking and entering and casual shootouts with the police on Monday mornings. Freelance mercs favor this gun for its uncompromising power in a semi-automatic package. The menacing effect it creates is just icing on the cake."
SWEP.Trivia_Manufacturer = "Armera Custom"
SWEP.Trivia_Calibre = ".50 Action Express"
SWEP.Trivia_Mechanism = "Gas-Operated"
SWEP.Trivia_Country = "USA/Israel"
SWEP.Trivia_Year = 1991

SWEP.Slot = 1

if GetConVar("arccw_truenames"):GetBool() then SWEP.PrintName = SWEP.TrueName end

SWEP.UseHands = true

SWEP.ViewModel = "models/weapons/arccw/c_kf2_deagle.mdl"
SWEP.WorldModel = "models/weapons/arccw/w_kf2_deagle.mdl"
SWEP.ViewModelFOV = 65

SWEP.DefaultSkin = 1

SWEP.Damage = 120
SWEP.DamageMin = 80 -- damage done at maximum range
SWEP.Range = 50 -- in METRES
SWEP.Penetration = 12
SWEP.DamageType = DMG_BULLET
SWEP.ShootEntity = nil -- entity to fire, if any
SWEP.MuzzleVelocity = 500 -- projectile or phys bullet muzzle velocity
-- IN M/S

SWEP.CanFireUnderwater = false

SWEP.TracerNum = 1 -- tracer every X
SWEP.TracerCol = Color(255, 25, 25)
SWEP.TracerWidth = 3

SWEP.ChamberSize = 1 -- how many rounds can be chambered.
SWEP.Primary.ClipSize = 7 -- DefaultClip is automatically set.
SWEP.ExtendedClipSize = 12
SWEP.ReducedClipSize = 5

SWEP.Recoil = 3.5
SWEP.RecoilSide = 1.2
SWEP.RecoilRise = 1
SWEP.MaxRecoilBlowback = 2

SWEP.Delay = 60 / 300 -- 60 / RPM.
SWEP.Num = 1 -- number of shots per trigger pull.
SWEP.Firemodes = {
    {
        Mode = 1,
    },
    {
        Mode = 0
    }
}

SWEP.NPCWeaponType = "weapon_357"
SWEP.NPCWeight = 75

SWEP.AccuracyMOA = 5 -- accuracy in Minutes of Angle. There are 60 MOA in a degree.
SWEP.HipDispersion = 250 -- inaccuracy added by hip firing.
SWEP.MoveDispersion = 250

SWEP.Primary.Ammo = "357" -- what ammo type the gun uses
SWEP.MagID = "gce" -- the magazine pool this gun draws from

SWEP.ShootVol = 130 -- volume of shoot sound
SWEP.ShootPitch = 95 -- pitch of shoot sound

SWEP.ShootSound = "weapons/arccw/arccw_rocky_kf2_deagle/gunfire/magnum_shoot.wav"
SWEP.ShootSoundSilenced = "weapons/arccw/usp/usp_01.wav"
SWEP.DistantShootSound = "weapons/arccw/deagle/deagle-1-distant.wav"

SWEP.MuzzleEffect = "muzzleflash_pistol_deagle"
SWEP.ShellModel = "models/shells/shell_9mm.mdl"
SWEP.ShellScale = 2
SWEP.ShellPitch = 85

SWEP.MuzzleEffectAttachment = 1 -- which attachment to put the muzzle on
SWEP.CaseEffectAttachment = 2 -- which attachment to put the case effect on

SWEP.SightTime = 0.225

SWEP.SpeedMult = 0.975
SWEP.SightedSpeedMult = 0.75

SWEP.BarrelLength = 22

SWEP.BulletBones = { -- the bone that represents bullets in gun/mag
    -- [0] = "bulletchamber",
    -- [1] = "bullet1"
}

SWEP.ProceduralRegularFire = false
SWEP.ProceduralIronFire = true

SWEP.CaseBones = {}

SWEP.IronSightStruct = {
    Pos = Vector(-3.941, -3.227, 1.379),
    Ang = Angle(-0.002, -1, -0.53),
	-- Pos = Vector(10.854, -20, 2.411),
    -- Ang = Angle(0, 90, 0),
    Magnification = 1.1,
    SwitchToSound = "", -- sound that plays when switching to this sight
}

SWEP.HoldtypeHolstered = "normal"
SWEP.HoldtypeActive = "pistol"
SWEP.HoldtypeSights = "revolver"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER

SWEP.ActivePos = Vector(-2, 0, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(-2, -7.145, -11.561)
SWEP.HolsterAng = Angle(36.533, 0, 0)

SWEP.BarrelOffsetSighted = Vector(1, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.ExtraSightDist = 15

SWEP.AttachmentElements = {

}

SWEP.Attachments = {
    {
        PrintName = "Optic", -- print name
        DefaultAttName = "Iron Sights",
        Slot = "optic_lp", -- what kind of attachments can fit here, can be string or table
        Bone = "RW_Weapon", -- relevant bone any attachments will be mostly referring to
        Offset = {
            vpos = Vector(6, 0, 3.7), -- offset that the attachment will be relative to the bone
            vang = Angle(0, 0, 0),
            wpos = Vector(8.75, 2.15, -4.8),
            wang = Angle(-6, -1, 172)
        },
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "Standard Muzzle",
        Slot = "muzzle",
        Bone = "RW_Weapon",
        Offset = {
            vpos = Vector(8.85, 0, 3),
            vang = Angle(0, 0, 0),
            wpos = Vector(11.6, 2.1, -4.428),
            wang = Angle(-6, -1, 172)
        },
    },
    {
        PrintName = "Underbarrel",
        Slot = {"foregrip_pistol", "style_pistol"},
        Bone = "RW_Weapon",
        Offset = {
            vpos = Vector(3.2, 0, 1.5),
            vang = Angle(0, 0, 0),
            wpos = Vector(6, 2, -2.622),
            wang = Angle(-6, -1, 172)
        },
    },
    {
        PrintName = "Tactical",
        Slot = "tac_pistol",
        Bone = "RW_Weapon",
        Offset = {
            vpos = Vector(7, 0, 1.64), -- offset that the attachment will be relative to the bone
            vang = Angle(0, 0, 0),
            wpos = Vector(10, 1.9, -3),
            wang = Angle(-6, -1, 172)
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
        DefaultAttName = "No Stock",
        InstalledEles = {"stock"},
    },
    {
        PrintName = "Fire Group",
        Slot = "fcg",
        DefaultAttName = "Standard FCG"
    },
    {
        PrintName = "Ammo Type",
        Slot = "ammo_bullet"
    },
    {
        PrintName = "Perk",
        Slot = "perk"
    },
    {
        PrintName = "Charm",
        Slot = "charm",
		VMScale = Vector(0.75, 0.75, 0.75),
		WMScale = Vector(0.75, 0.75, 0.75),
        FreeSlot = true,
        Bone = "RW_Weapon", -- relevant bone any attachments will be mostly referring to
        Offset = {
            vpos = Vector(7.9, -0.5, 2.6), -- offset that the attachment will be relative to the bone
            vang = Angle(0, 0, 0),
            wpos = Vector(10.75, 2.5, -4),
            wang = Angle(0, -1, 172)
        },
    },
}

-- draw
-- holster
-- reload
-- fire
-- cycle (for bolt actions)
-- append _empty for empty variation

SWEP.Animations = {
	["idle"] = {
        Source = "idle",
        --Time = 2.5,
        LHIK = false,
    },
	["idle_empty"] = {
        Source = "idle_empty",
        --Time = 2.5,
        LHIK = false,
    },
    ["ready"] = {
        Source = "deploy",
        --Time = 2.5,
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 0.75,
    },
    ["draw_empty"] = {
        Source = "draw_empty",
        --Time = 2.5,
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 1,
        SoundTable = {
            {
            s = "weapons/arccw/usp/usp_draw.wav",
            t = 0
            }
        }
    },
    ["draw"] = {
        Source = "draw",
        --Time = 2.5,
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 1,
        SoundTable = {
            {
            s = "weapons/arccw/usp/usp_draw.wav",
            t = 0
            }
        }
    },
    ["fire"] = {
        Source = {"fire"},
        Time = 0.7,
        ShellEjectAt = 0,
    },
    ["fire_empty"] = {
        Source = "fire_last",
        --Time = 0.5,
        Time = 0.5,
        ShellEjectAt = 0,
    },
    ["fire_iron"] = {
        Source = "fire",
        --Time = 0.5,
        ShellEjectAt = 0,
    },
    ["fire_iron_empty"] = {
        Source = "fire_last",
        --Time = 0.5,
        ShellEjectAt = 0,
    },
    ["reload"] = {
        Source = "reload",
        --Time = 2.5,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        Checkpoints = {24, 39, 47},
        --FrameRate = 30,
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 0.6,
    },
    ["reload_empty"] = {
        Source = "reload_empty",
        --Time = 2.75,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        Checkpoints = {24, 39, 47},
        --FrameRate = 30,
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 0.6,
    },   
    ["bash"] = {
        Source = "bash",
    },
	 ["bash_empty"] = {
        Source = "bash_empty",
    },
}

sound.Add( {
	name = "Arccw_L4D2_Deagle.1",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 120,
	pitch = { 95, 110 },
	sound = "weapons/arccw/l4d2_rocky_kf2_deagle/gunfire/magnum_shoot.wav"
} )

sound.Add( {
	name = "Arccw_L4D2_Deagle.Deploy",
	channel = CHAN_USER_BASE+12,
	volume = 1.0,
	level = 80,
	pitch = { 95, 110 },
	sound = "weapons/arccw/l4d2_rocky_kf2_deagle/gunother/pistol_deploy_1.wav"
} )

sound.Add( {
	name = "Arccw_L4D2_Deagle.SlideForward",
	channel = CHAN_USER_BASE+11,
	volume = 1.0,
	level = 80,
	pitch = { 95, 110 },
	sound = "weapons/arccw/arccw_rocky_kf2_deagle/gunother/pistol_slideforward_1.wav"
} )

sound.Add( {
	name = "Arccw_L4D2_Deagle.SlideBack",
	channel = CHAN_USER_BASE+11,
	volume = 1.0,
	level = 80,
	pitch = { 95, 110 },
	sound = "weapons/arccw/arccw_rocky_kf2_deagle/gunother/pistol_slideback_1.wav"
} )

sound.Add( {
	name = "Arccw_L4D2_Deagle.ClipOut",
	channel = CHAN_USER_BASE+12,
	volume = 1.0,
	level = 80,
	pitch = { 95, 110 },
	sound = "weapons/arccw/arccw_rocky_kf2_deagle/gunother/pistol_clip_out_1.wav"
} )

sound.Add( {
	name = "Arccw_L4D2_Deagle.ClipIn",
	channel = CHAN_USER_BASE+12,
	volume = 1.0,
	level = 80,
	pitch = { 95, 110 },
	sound = "weapons/arccw/arccw_rocky_kf2_deagle/gunother/pistol_clip_in_1.wav"
} )

sound.Add( {
	name = "Arccw_L4D2_Deagle.ClipLocked",
	channel = CHAN_USER_BASE+12,
	volume = 1.0,
	level = 80,
	pitch = { 95, 110 },
	sound = "weapons/arccw/arccw_rocky_kf2_deagle/gunother/pistol_clip_locked_1.wav"
} )

sound.Add( {
	name = "Arccw_L4D2_Deagle.FullAutoButton",
	channel = CHAN_USER_BASE+12,
	volume = 1.0,
	level = 80,
	pitch = { 95, 110 },
	sound = "weapons/arccw/arccw_rocky_kf2_deagle/gunother/pistol_fullautobutton_1.wav"
} )

sound.Add( {
	name = "Arccw_L4D2_Deagle.HelpingHandRetract",
	channel = CHAN_USER_BASE+11,
	volume = 1.0,
	level = 80,
	pitch = { 95, 110 },
	sound = "weapons/arccw/arccw_rocky_kf2_deagle/gunother/pistol_helpinghandretract.wav"
} )




