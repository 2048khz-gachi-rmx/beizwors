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


local f = {
	"gachi",
	"playsound",
}

local urlps = {
	["q2f2laugh"] = "https://b.vaati.net/aruc.mp3",
	["cani"] = "http://vaati.net/Gachi/shared/ballz.mp3",
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

	for k,v in pairs(urlps) do

		if line == k then
			played = true
			net.Start("playsound")
				net.WriteString(v)
				net.WriteEntity(ply)
			net.Broadcast()
			ply.psCoolDown = CurTime()
		end

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