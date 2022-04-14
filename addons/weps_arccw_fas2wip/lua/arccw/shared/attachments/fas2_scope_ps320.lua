att.PrintName = "PS-320 ''VALDAY''"
att.Icon = Material("vgui/fas2atts/c79")
    att.Description = "PS-320 1x/6x scope designed by Valday."

att.Desc_Pros = {
    "Precision sight picture",
    "6x magnification",
}
att.Desc_Cons = {
    "Large size",
    "Visible scope glint"
}

att.Slot = "fas2_scope"

att.Model = "models/weapons/fas2/attachments/ps320.mdl"

att.AdditionalSights = {
    {
        Pos = Vector(-0.009, 7.3, -1.062),
        Ang = Angle(0, 0, 0),
        Magnification = 1,
        ScrollFunc = ArcCW.SCROLL_ZOOM,
        ZoomLevels = 1,
        ZoomSound = "fas2/sks/sks_insertlast.wav"
    }
}

att.ScopeGlint = true

att.Mult_GlintMagnitude = 0.5

att.Holosight = true
att.HolosightReticle = Material("sprites/fas2/scopes/ps320")
att.HolosightNoFlare = true
att.HolosightSize = 9.5
att.HolosightBone = "holosight"
att.HolosightPiece = "models/weapons/fas2/attachments/ps320_hsp.mdl"

att.HolosightMagnification = 8
att.HolosightBlackbox = true

att.HolosightMagnificationMin = 2
att.HolosightMagnificationMax = 8

att.ActivateElements = {"mount"}

att.AttachSound = "fas2/cstm/attach.wav"
att.DetachSound = "fas2/cstm/detach.wav"