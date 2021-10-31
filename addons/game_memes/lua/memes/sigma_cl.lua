local active = {}

hook.Add("Think", "sigma", function()
	if not active[1] then return end

	local me = LocalPlayer()

	for i=#active, 1, -1 do
		local dat = active[i]
		local ch, ply = dat[1], dat[2]

		if not IsValid(ch) or ch:GetState() == GMOD_CHANNEL_STOPPED or not IsValid(ply) then
			table.remove(active, i)
			ch:Stop()
			continue
		end

		if ply == me then continue end

		ch:SetPos(ply:GetPos() + ply:OBBCenter())
	end
end)

function shrigmaPlay(url, fn, who, ignore)
	local flags = ""

	if who == LocalPlayer() then
		flags = ""
	else
		flags = "3d"
	end

	if not ignore then
		for k,v in ipairs(active) do
			if v[2] == who and v[3] == fn then return end -- don't play again
		end
	end

	hdl.DownloadFile(url, fn):Then(function(self, fn)
		sound.PlayFile(fn, flags, function(ch)
			if not IsValid(ch) then return end
			--if who ~= LocalPlayer() then -- only others need to be 3d tracked
				active[#active + 1] = {ch, who, fn}
			--end
		end)
	end)
end

net.Receive("sigma_male", function()
	local who = net.ReadEntity()
	shrigmaPlay("http://vaati.net/Gachi/shared/sigma_pull.mp3", "shrigma.dat", who)
end)

net.Receive("playsound", function()
	local url, ply = net.ReadString(), net.ReadEntity()
	shrigmaPlay(url, url:match("[^/]+$"), ply, true)
end)

local tab = {
	[ "$pp_colour_addr" ] = 0,
	[ "$pp_colour_addg" ] = 0,
	[ "$pp_colour_addb" ] = 0,
	[ "$pp_colour_brightness" ] = 0,
	[ "$pp_colour_contrast" ] = 1,
	[ "$pp_colour_colour" ] = 0,
	[ "$pp_colour_mulr" ] = 0,
	[ "$pp_colour_mulg" ] = 0,
	[ "$pp_colour_mulb" ] = 0
}

local anim = Animatable("sigma")

hook.Add( "RenderScreenspaceEffects", "color_modify_example", function()
	local wep = LocalPlayer():GetActiveWeapon()
	if IsValid(wep) and wep:GetClass() == "arccw_p228" then
		anim:To("fr", 1, 0.6, 0, 1)
	else
		anim:To("fr", 0, 1, 0, 1)
	end

	local fr = (anim.fr or 0)

	tab[ "$pp_colour_colour" ] = 1 - fr
	tab[ "$pp_colour_addr" ] = 0 - fr * 0.1
	tab[ "$pp_colour_addg" ] = 0 - fr * 0.1
	tab[ "$pp_colour_addb" ] = 0 - fr * 0.1
	tab[ "$pp_colour_mulr" ] = 0 + fr * 0.1
	tab[ "$pp_colour_mulg" ] = 0 + fr * 0.1
	tab[ "$pp_colour_mulb" ] = 0 + fr * 0.1
	DrawColorModify( tab )
end)