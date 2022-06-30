--
surface.CreateFont( "GModNotify", {
	font	= "Arial",
	size	= 21,
	weight	= 0
} )

NOTIFY_GENERIC	= 0
NOTIFY_ERROR	= 1
NOTIFY_UNDO		= 2
NOTIFY_HINT		= 3
NOTIFY_CLEANUP	= 4

module( "notification", package.seeall )

NoticeMaterial = NoticeMaterial or {}

NoticeMaterial[ NOTIFY_GENERIC ]	= Material( "vgui/notices/generic" )
NoticeMaterial[ NOTIFY_ERROR ]		= Material( "vgui/notices/error" )
NoticeMaterial[ NOTIFY_UNDO ]		= Material( "vgui/notices/undo" )
NoticeMaterial[ NOTIFY_HINT ]		= Material( "vgui/notices/hint" )
NoticeMaterial[ NOTIFY_CLEANUP ]	= Material( "vgui/notices/cleanup" )

Notices = Notices or {}

function AddProgress( uid, text, frac )

	if ( IsValid( Notices[ uid ] ) ) then

		Notices[ uid ].StartTime = SysTime()
		Notices[ uid ].Length = -1
		Notices[ uid ]:SetText( text )
		Notices[ uid ]:SetProgress( frac )
		return

	end

	local parent = nil
	if ( GetOverlayPanel ) then parent = GetOverlayPanel() end

	local Panel = vgui.Create( "NoticePanel", parent )
	Panel.StartTime = SysTime()
	Panel.Length = -1
	Panel.VelX = -5
	Panel.VelY = 0
	Panel.fx = ScrW() + 200
	Panel.fy = ScrH()
	Panel:SetAlpha( 255 )
	Panel:SetText( text )
	Panel:SetPos( Panel.fx, Panel.fy )
	Panel:SetProgress( frac )

	Notices[ uid ] = Panel

end

function Kill( uid )

	if ( !IsValid( Notices[ uid ] ) ) then return end

	Notices[ uid ].StartTime = SysTime()
	Notices[ uid ].Length = 0.8

end

function AddLegacy( text, type, length )

	local parent = nil
	if ( GetOverlayPanel ) then parent = GetOverlayPanel() end

	local Panel = vgui.Create( "NoticePanel", parent )
	Panel.StartTime = SysTime()
	Panel.Length = math.max( length or 2, 0 )
	Panel.VelX = -5
	Panel.VelY = 0
	Panel.fx = ScrW() + 200
	Panel.fy = ScrH()
	Panel:SetAlpha( 255 )
	Panel:SetText( text )
	Panel:SetLegacyType( type )
	Panel:SetPos( Panel.fx, Panel.fy )

	Panel.Number = table.insert( Notices, Panel )

end

function AddTimed(text, type, length)
	local parent = nil
	if ( GetOverlayPanel ) then parent = GetOverlayPanel() end

	local Panel = vgui.Create( "NoticePanel", parent )
	Panel.StartTime = SysTime()
	Panel.Length = math.max( length or 2, 0 )
	Panel.VelX = -5
	Panel.VelY = 0
	Panel.fx = ScrW() + 200
	Panel.fy = ScrH()
	Panel:SetAlpha( 255 )
	Panel:SetText( text )
	Panel:SetLegacyType( type )
	Panel:SetPos( Panel.fx, Panel.fy )

	Panel.Number = table.insert( Notices, Panel )

	return Panel
end

-- This is ugly because it's ripped straight from the old notice system
local function UpdateNotice( pnl, total_h )

	local x = pnl.fx
	local y = pnl.fy

	local w = pnl:GetWide() + 16
	local h = pnl:GetTall() + 4

	local ideal_y = ScrH() - 150 - h - total_h
	local ideal_x = ScrW() - w - 20

	local timeleft = pnl.StartTime - ( SysTime() - pnl.Length )
	if ( pnl.Length < 0 ) then timeleft = 1 end

	-- Cartoon style about to go thing
	if ( timeleft < 0.6 ) then
		ideal_x = ideal_x - 64
	end

	-- Gone!
	if ( timeleft < 0.3 ) then
		ideal_x = ScrW() + w
	end

	local spd = RealFrameTime() * 20

	y = y + pnl.VelY * spd
	x = x + pnl.VelX * spd

	local dist = ideal_y - y
	pnl.VelY = pnl.VelY + dist * spd * 1
	if ( math.abs( dist ) < 2 && math.abs( pnl.VelY ) < 0.1 ) then pnl.VelY = 0 end
	dist = ideal_x - x
	pnl.VelX = pnl.VelX + dist * spd * 1
	if ( math.abs( dist ) < 2 && math.abs( pnl.VelX ) < 0.1 ) then pnl.VelX = 0 end

	-- Friction.. kind of FPS independant.
	pnl.VelX = pnl.VelX * ( 0.95 - RealFrameTime() * 10 )
	pnl.VelY = pnl.VelY * ( 0.95 - RealFrameTime() * 10 )

	pnl.fx = x
	pnl.fy = y

	-- If the panel is too high up (out of screen), do not update its position. This lags a lot when there are lot of panels outside of the screen
	if ( ideal_y > -ScrH() ) then
		pnl:SetPos( pnl.fx, pnl.fy )
	end

	return total_h + h

end

local function Update()
	if ( !Notices ) then return end

	for i=#Notices, 1, -1 do
		local pnl = Notices[i]
		if ( not pnl:IsValid() or pnl:KillSelf() ) then
			table.remove(Notices, i)
		end
	end

	local h = 0

	for key, pnl in pairs( Notices ) do
		h = UpdateNotice( pnl, h )
	end

	for i=#Notices, 1, -1 do
		local pnl = Notices[i]
		pnl.Number = i
	end

end

hook.Add( "Think", "NotificationThink", Update )

function Paint(self, w, h)
	local rbox = DarkHUD.RoundedBoxCorneredSize
	if not rbox then return end

	local shouldDraw = LocalPlayer():IsValid() and
		(not LocalPlayer():GetActiveWeapon():IsValid() or
		LocalPlayer():GetActiveWeapon():GetClass() ~= "gmod_camera" )

	if IsValid( self.Label ) then self.Label:SetVisible( shouldDraw ) end
	if IsValid( self.Image ) then self.Image:SetVisible( shouldDraw ) end

	if not shouldDraw then return end
	--if ( !self.Progress ) then return end

	local timeLeft = self.StartTime - (SysTime() - self.Length)
	local fr = timeLeft / self.Length

	local sx, sy = self:LocalToScreen(0, 0)

	local hd = self.HeaderSize or 12
	rbox(8, 0, 0, w, hd, Colors.FrameHeader, 8, 8)
	render.PushScissorRect(sx, sy, sx + w * fr, sy + h)
		rbox(8, 0, 0, w, hd, Colors.White, 8, 8, 0, 0)
	render.PopScissorRect()

	rbox(8, 0, hd, w, h - hd, self:GetBackgroundColor(), 0, 0, 8, 8)

	

	
end

local PANEL = {}

function PANEL:Init()
	self.HeaderSize = 12
	self:DockPadding( 4, self.HeaderSize + 2, 4, 4 )

	self.Label = vgui.Create( "DLabel", self )
	self.Label:Dock( FILL )
	self.Label:SetFont( "OSB22" )
	self.Label:SetTextColor( color_white )
	self.Label:SetExpensiveShadow( 1, Color( 0, 0, 0, 200 ) )
	self.Label:SetContentAlignment( 5 )

	local col = Color(60, 60, 60, 255 * 0.7)

	self:SetBackgroundColor(col)
end

function PANEL:SetText( txt )

	self.Label:SetText( txt )
	self:SizeToContents()

end

function PANEL:SizeToContents()

	self.Label:SizeToContents()

	local width, tall = self.Label:GetSize()

	tall = math.max(tall, 28) + self.HeaderSize + 8
	width = width + 20

	if ( IsValid( self.Image ) ) then
		local h = self.Image:GetTall()
		width = width + h + 4

		local _, t, _, b = self:GetDockPadding()

		local imTop = self.HeaderSize + 2 - t
		local imBot = tall - t - h - b

		local spread = math.ceil((imTop + imBot) / 2)

		self.Image:DockMargin( 0,
			spread,
			0,
			spread)
	end

	self:SetSize( width, tall )

	self:InvalidateLayout()

end

function PANEL:SetLegacyType( t )

	self.Image = vgui.Create( "DImageButton", self )
	self.Image:SetMaterial( NoticeMaterial[ t ] )
	self.Image:SetSize( 28, 28 )
	self.Image:Dock( LEFT )
	self.Image:DockMargin( 0, 0, 4, 0 )
	self.Image.DoClick = function()
		self.StartTime = 0
	end

	self:SizeToContents()

end

function PANEL:Paint( w, h )
	notification.Paint(self, w, h)
end

function PANEL:SetProgress( frac )

	self.Progress = true
	self.ProgressFrac = frac

	self:SizeToContents()

end

function PANEL:KillSelf()

	-- Infinite length
	if ( self.Length < 0 ) then return false end

	if ( self.StartTime + self.Length < SysTime() ) then
		self:Remove()
		return true
	end

	return false

end

vgui.Register( "NoticePanel", PANEL, "DPanel" )
