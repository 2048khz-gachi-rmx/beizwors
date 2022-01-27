sfx = sfx or {}

function sfx.ClickIn()
	surface.PlaySound("vgui/grp/plastic_in.mp3")
end

function sfx.ClickOut()
	surface.PlaySound("vgui/grp/plastic_out.mp3")
end

function sfx.Success(n)
	n = math.Clamp( math.floor(n or math.random(1, 3)), 1, 3 )
	surface.PlaySound( ("vgui/grp/good%02d.mp3"):format(n) )
end

function sfx.Fail()
	surface.PlaySound( "vgui/grp/bad01.mp3" )
end
sfx.Failure = sfx.Fail