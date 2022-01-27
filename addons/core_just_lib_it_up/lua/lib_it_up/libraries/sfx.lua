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


-- checks
function sfx.CheckIn()
	surface.PlaySound( "vgui/grp/check_in.mp3" )
end

function sfx.CheckOut()
	surface.PlaySound( "vgui/grp/check_out.mp3" )
end

function sfx.Check(b)
	if b then sfx.CheckIn() else sfx.CheckOut() end
end

-- sets
function sfx.SetIn()
	surface.PlaySound( "vgui/grp/set_in.mp3" )
end

function sfx.SetOut()
	surface.PlaySound( "vgui/grp/set_out.mp3" )
end

	function sfx.Set(b)
		if b then sfx.SetIn() else sfx.SetOut() end
	end

function sfx.SetDone()
	surface.PlaySound( "vgui/grp/set_done.mp3" )
end

sfx.SetFinish = sfx.SetDone


