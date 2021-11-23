CUM.CurCat = "Fun"

local log = CUM.Log

local function GuessPlayer(cur, ply, arg)

	if not ply and not arg then return "^", cur end

	local plyr = CUM.ParsePlayer(ply)

	if not plyr and arg then
		local plyr2 = CUM.ParsePlayer(arg)

		if plyr2 then
			plyr = plyr2

			arg = ply
		end
	elseif not plyr and not arg and tonumber(ply) then --ply is number
		return "^", tonumber(ply)
	end

	if not plyr and not arg then return "err" end

	local num = tonumber(arg or cur)

	if not plyr then
		return "^", num
	elseif plyr then
		return plyr, num
	else
		return false, ply
	end

end


CUM.AddCommand({"armor", "a"}, function(_, ply, amt)
	if not IsValid(ply) then return end
	ply:SetArmor(amt)
end)
	:AddPlayerArg(true, GuessPlayer, "Player whose armor to set", true)
	:AddNumberArg(true, function(ply, num, ...)

		return num or (IsValid(ply) and ply:GetMaxHealth()) or nil
	end, "Armor to set to")

	:SetReportFunc(function(self, rply, caller, ply, amt)
		return "{1} set {2}'s armor to {3}.", {[3] = "<col=50,150,250>" .. tostring(amt)}
	end)

	:SetSilent(true)

CUM.AddCommand({"hp", "health"}, function(_, ply, amt, ...)
	if not IsValid(ply) then return end
	ply:SetHealth(amt or ply:GetMaxHealth())
end)
	:AddPlayerArg(true, GuessPlayer, "Player whose health to set", true)

	:AddNumberArg(true, function(ply, num, ...)
		return tonumber(num) or tonumber(ply) or (IsValid(ply) and ply:GetMaxHealth()) or 100
	end, "Health to set to")

	:SetReportFunc(function(self, rply, caller, ply, amt)
		return "{1} set {2}'s health to {3}.", {[3] = "<col=100,220,100>" .. tostring(amt)}
	end)

	:SetSilent(true)


CUM.AddCommand("slap", function(_, ply, amt)
	if not ply then return end
	ply:SetVelocity(Vector(math.random(-amt/2, amt/2), math.random(-amt/2, amt/2), amt))
end)
	:AddPlayerArg(true, "Player to slap")
	:AddNumberArg(true, 400, "Velocity to slap with")

	:SetReportFunc(function(self, rply, caller, ply, amt)
		local sa = not IsValid(rply) or rply:IsSuperAdmin()
		local rep = {}

		if sa then
			rep[1] = caller
		else
			rep[1] = "<col=0,60,100>Someone"
		end

		return "{1} slapped {2}.", rep
	end)

	:SetHiddenCaller(true)
	:SetSilent(true)
	:SetDescription("Slaps a player(optionally with set velocity).")


local function doSound(ply, url)
	net.Start("playsound")
		net.WriteString(url)
		net.WriteEntity(ply)
	net.Broadcast()
end


local f = {
	"gachi",
	"playsound",
}

local urlps = {
	["q2f2laugh"] = "https://b.vaati.net/aruc.mp3",
	["cani"] = "http://vaati.net/Gachi/shared/ballz.mp3",
	["kys"] = "http://vaati.net/Gachi/shared/kys.mp3",
	["kys_now"] = function(ply)
		local thunders = 4
		local ttbl = {}
		for i=1, 4 do ttbl[i] = i end
		table.Shuffle(ttbl)

		local snd = "ambient/ambience/rainscapes/thunder_close0%d.wav"

		local thunder_1 = snd:format(ttbl[1])
		local thunder_2 = snd:format(ttbl[1])
		local lightning = "ambient/weather/thunderstorm/lightning_strike_%d.wav"
		local light_rand = lightning:format(math.random(1, 4))

		ply:SetNWVector("kys_where", ply:EyePos() + VectorRand(-256, 256) + Vector(0, 0, 1024))

		sound.Play(thunder_1,
			ply:GetPos() + Vector(0, 0, 128),
		90, 100, 1)

		local delay = 1.3
		ply:Timer("kys", delay, 1, function()
			sound.Play(thunder_2,
				ply:GetPos() + Vector(0, 0, 128),
			90, 100, 1)
			doSound(ply, "http://vaati.net/Gachi/shared/kys_you_should.mp3")
		end)

		delay = delay + 3.2
		ply:Timer("kys_2", delay, 1, function()
			for i=1, 4 do
				sound.Play(lightning:format(i),
					ply:GetPos() + Vector(0, 0, 128),
				90, 100, 1)
			end
		end)

		delay = delay + 0.1
		ply:Timer("kys_2.5", delay, 1, doSound, "http://vaati.net/Gachi/shared/kys_NOW.mp3")

		delay = delay + 0.4
		ply:Timer("kys_3", delay, 1, function()
			ply:Kill()

			local ef = EffectData()
			ef:SetOrigin(ply:GetPos() + ply:OBBCenter())
			ef:SetScale(200)
			ef:SetNormal(vector_up)
			ef:SetEntity(ply)
			util.Effect("ThumperDust", ef)
			util.Effect("cball_explode", ef)

			for i=1, 2 do
				sound.Play(("ambient/energy/weld%d.wav"):format(i),
					ply:GetPos() + ply:OBBCenter(),
				90, 100, 1)
			end

			sound.Play(("ambient/explosions/explode_%d.wav"):format(math.random(1, 9)),
				ply:GetPos() + ply:OBBCenter(),
			90, 100, 1)

			util.ScreenShake(ply:GetPos() + ply:OBBCenter(), 8, 1024, 6, 512)

			ply:Timer("kys_reset", 1, function()
				ply:SetNWFloat("kys_now", 0)
			end)
		end)

		ply:SetNWFloat("kys_now", CurTime() + delay)
		ply:SetNWFloat("kys_start", CurTime())
	end
}

CUM.AddCommand("ps", function(_, ply, line)
	if not GachiRP then return end
	if not IsValid(ply) then return false, "Console?" end

	if not BaseWars.IsRetarded(ply) and
		ply.psCoolDown and CurTime() - ply.psCoolDown < 2 then return false end

	if not line or line == "" then

		for k,v in pairs(f) do
			local snds = file.Find("sound/" .. v .. "/*.ogg","MOD", "namedesc")
			ply:ConsoleAddText(Color(150,150,230), v .. "/\n")
			for i=1,#snds do
				ply:ConsoleAddText(Color(100,200,100), "  " .. snds[i] .. "\n")
			end

		end

		ply:ChatPrint("All sounds are printed to console.")

		return false
	end

	line = line:lower()

	local played = false

	for k,v in pairs(f) do
		local snds = file.Find("sound/" .. v .. "/*.ogg","MOD", "namedesc")

		for k, file in pairs(snds) do
			if line .. ".ogg"==file then
				played = true
				ply.psCoolDown = CurTime()
				ply:EmitSound(v .. "/" .. line .. '.ogg', 120, 100, 1, CHAN_AUTO )
			break end
		end

	end

	if urlps[line] then
		played = true
		if isstring(urlps[line]) then
			doSound(ply, urlps[line])
		elseif isfunction(urlps[line]) then
			urlps[line](ply)
		end

		ply.psCoolDown = CurTime()
	end

	if not played then
		ply:PrintMessage(3, "sound '" .. line .. ".ogg' not found")
		return false
	end


end)
:SetPerms("user")
:SetSilent(true)
:SetDescription("Play one of the predefined sounds.")
:SetReportFunc(function(self, rply, caller, caller2, snd)
	if not snd or snd=="" then return end

	if not IsValid(rply) or rply:Distance(caller) < 768 or rply == caller then
		return "{1} played sound {2}.", {[2] = "<color=100,230,100>"..snd..".ogg"}
	end
end)
:AddStringArg(true, "Sound to play.")
:AddCallerArg()