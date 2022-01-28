setfenv(1, _G)

function scale(n)
	return n / 900 * ScrH()
end

function scaleW(n)
	return n / 1600 * ScrW()
end

local NOOOOO_MY_GARBAGE_COLLECTION = { type = '2D' }

function cam.Start2D()
	return cam.Start(NOOOOO_MY_GARBAGE_COLLECTION)
end

local NOOOOO_MY_GARBAGE_COLLECTION_3d = { type = '3D' }

function cam.Start3D( pos, ang, fov, x, y, w, h, znear, zfar )
	local tab = NOOOOO_MY_GARBAGE_COLLECTION_3d

	tab.origin = pos
	tab.angles = ang
	tab.fov = fov
	tab.x			= x
	tab.y			= y
	tab.w			= w
	tab.h			= h
	tab.aspect		= w and h and ( w / h ) or nil
	tab.znear	= znear
	tab.zfar	= zfar

	return cam.Start( tab )
end

_realScr = _realScr or {}
_realScrFs = _realScrFs or {ScrW, ScrH}
_curScr = _curScr or {}

function cam.SetFakeRes(w, h)
	if not w then
		ScrW = _realScrFs[1]
		ScrH = _realScrFs[2]

		_curScr = {}
		return
	end

	if not _realScr[1] then
		_realScr = {ScrW(), ScrH()}
	end

	ScrW = function() return w end
	ScrH = function() return w end

	_curScr = {w, h}
end

hook.Add("HUDPaint", "DrawFakeScrW", function()
	if not _curScr[1] then return end
	surface.SetDrawColor(Colors.Red)
	surface.DrawOutlinedRect(--_realScr[1] / 2 - _curScr[1] / 2, _realScr[2] / 2 - _curScr[2] / 2,
		0, 0, _curScr[1], _curScr[2])
end)