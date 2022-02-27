local bw = BaseWars.Bases
bw.HUD = bw.HUD or Emitter()
local hud = bw.HUD

include("hud/base_painter_ext.lua")

hook.Add("HUDPaint", "basePainter", function()
	if not hud.DoPainters then return end

	local lp = LocalPlayer()
	local base, zone = lp:BW_GetBase(), lp:BW_GetZone()
	hud.DoPainters(base, zone)
end)