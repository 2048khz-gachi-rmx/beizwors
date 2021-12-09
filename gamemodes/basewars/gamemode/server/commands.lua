BaseWars.Commands = {
	cmds = {},
}

if ulx or ulib then
	BaseWars.Commands.Pattern = "[/|%.]"
else
	BaseWars.Commands.Pattern = "[!|/|%.]"
end

function BaseWars.Commands.ParseArgs(str)

	local ret 		= {}
	local InString 	= false
	local strchar 	= ""
	local chr 		= ""
	local escaped 	= false

	for i=1, #str do

		local char = str[i]

		if escaped then

			chr = chr..char
			escaped = false

		continue end

		if char:find("[\"|']") and not InString and not escaped then

			InString 	= true
			strchar 	= char

		elseif char:find("[\\]") then

			escaped 	= true

			continue

		elseif InString and char == strchar then

			ret[#ret+1] = chr:Trim()
			chr 		= ""
			InString 	= false

		elseif char:find("[ ]") and not InString and chr ~= "" then

			ret[#ret+1] = chr
			chr 		= ""

		else
			chr = chr .. char

		end

	end

	if chr:Trim():len() ~= 0 then

		ret[#ret+1] = chr

	end

	return ret

end

function BaseWars.Commands.CallCommand(ply, cmd, line, args)

	MsgC(Color(240, 50, 50), "[BW] Command ", Color(255, 255, 255), ply, " -> ", Color(220, 220, 220), cmd .. (line or "") , "\n")

	local ok, msg = pcall(function()

		local allowed, reason = hook.Run("BaseWarsCommand", cmd, ply, line, unpack(args))

		cmd = BaseWars.Commands.cmds[cmd]

		if allowed ~= false then

			if easylua then easylua.Start(ply) end

				allowed, reason = cmd.CallBack(ply, line, unpack(args))

			if easylua then easylua.End() end

		end

		if ply.IsValid() then

			if allowed == false then

				ply:EmitSound("buttons/button8.wav")

				if reason then

					ply:SendLua(string.format([[local s = "%s" notification.AddLegacy(s, 1, 4)]], reason))

				end

			end

		end
	end)

	if not ok then

		ErrorNoHalt(msg)

		return msg

	end

end

function BaseWars.Commands.ConCommand(ply, cmd, args, line)

	local Cmd = args[1]
	if not Cmd then return end

	local TblCmd = BaseWars.Commands.cmds[Cmd]
	if not TblCmd then return end

	if not IsValid(ply) or (TblCmd.IsAdmin and not ply:IsAdmin()) then return end

	if ply.IsBanned and ply:IsBanned() and not ply:IsAdmin() then return end

	table.remove(args, 1)

	BaseWars.Commands.CallCommand(ply, Cmd, table.concat(args, " "), args)

end

function BaseWars.Commands.SayCommand(ply, txt, team)

	if not txt:sub(1, 1):find(BaseWars.Commands.Pattern) then return end

	local cmd 	= txt:match(BaseWars.Commands.Pattern .. "(.-) ") or txt:match(BaseWars.Commands.Pattern .. "(.+)") or ""
	local line 	= txt:match(BaseWars.Commands.Pattern .. ".- (.+)")

	cmd = cmd:lower()

	if not cmd then return end

	local TblCmd = BaseWars.Commands.cmds[cmd]
	if not TblCmd then return end

	if not IsValid(ply) or (TblCmd.IsAdmin and not ply:IsAdmin()) then return end

	BaseWars.Commands.CallCommand(ply, cmd, line, line and BaseWars.Commands.ParseArgs(line) or {})

	return ""

end

function BaseWars.Commands.AddCommand(cmd, callback, admin)

	if istable(cmd) then

		for k, v in next, cmd do

			BaseWars.Commands.AddCommand(v, callback, admin)

		end

		return

	end

	BaseWars.Commands.cmds[cmd] 	= {CallBack = callback, IsAdmin = admin, Cmd = cmd}

end

concommand.Add("basewars", BaseWars.Commands.ConCommand)
hook.Add("PlayerSay", "BaseWars.Commands", BaseWars.Commands.SayCommand)

local dist = 128^2

local function Upgradable(ply, ent)
	return IsValid(ent) and ply:EyePos():DistToSqr( ent:GetPos() ) < dist and ent.RequestUpgrade
end

local function Upgrade(ply, amt, ent)

	local trace = ply:GetEyeTrace()

	ent = ent or trace.Entity
	if not Upgradable(ply, ent) then return false end

	local canTimes = ent.CanUpgradeTimes and ent:CanUpgradeTimes() or
		ent.MaxLevel - (ent.GetLevel and ent:GetLevel() or ent.Level or ent.MaxLevel)

	if amt == "max" then
		amt = canTimes
	else
		amt = tonumber(amt) or 1
		amt = math.min(amt, canTimes)
	end

	for i=1, amt do
		local ok = ent:RequestUpgrade(ply, i, amt)
		if ok == false then break end
	end
end

BaseWars.Commands.AddCommand({"upg", "upgrade", "upgr"}, function(ply, amount)
	Upgrade(ply, amount)
end, false)

util.AddNetworkString("BW.Upgrade")

net.Receive("BW.Upgrade", function(len, ply)
	local ent = net.ReadEntity()
	local lvs = net.ReadUInt(8)
	Upgrade(ply, lvs, ent)
end)

BaseWars.Commands.AddCommand({"max", "maxupg", "maxupgrade"}, function(ply)
	Upgrade(ply, "max")
end, false)

BaseWars.Commands.AddCommand({"tell", "msg"}, function(ply, line, who)
	if not who then return false, "Specify a player!" end

	local Targ = easylua.FindEntity(who, true)

	if not IsPlayer(Targ) then return false, ("No player `%s` found!"):format(who) end

	local Msg = line:sub(#who + 1):Trim()
	Targ:ChatPrint(ply:Nick() .. " -> " .. Msg)
end, false)

BaseWars.Commands.AddCommand("psa", function(ply, line, text)
	if text then
		BroadcastLua([[BaseWars.PSAText = "]] .. line .. [["]])
	else
		BroadcastLua([[BaseWars.PSAText = nil]])
	end
end, true)

BaseWars.Commands.AddCommand({"sell", "destroy", "remove"}, function(ply)

	local trace = ply:GetEyeTrace()

	local ent = trace.Entity
	local wth, has = BaseWars.Worth.Get(ent)
	if not has then return false end

	local own = IsValid(ent) and ent:BW_GetOwner()
	if own ~= ply:GetPInfo() then return false end

	if ply:InRaid() then return false end

	BaseWars.UTIL.PayOut(ent, ply)
	ent:Remove()

end, false)

BaseWars.Commands.AddCommand({"sellall"}, function(ply, line, who, amount)

	timer.Simple(15, function()
		if not IsPlayer(ply) then return end -- left?
		if ply:InRaid() then ply:ChatAddText(Color(50, 150, 250), "Your /sellall command was cancelled because you were raided.") return end

		BaseWars.Worth.RefundAll(ply, true)
	end)

	ChatAddText(Color(230, 80, 80), ply:Nick() .. "'s entities will be sold in 15 seconds!")

end, false)

BaseWars.Commands.AddCommand({"dropmoney", "give", "givemoney"}, function(ply)
	ply:ChatAddText(Colors.Error, "Transferring money is disabled.")
end, false)

BaseWars.Commands.AddCommand({"dw", "dropwep", "drop", "dropweapon"}, function(ply)
	local Wep = ply:GetActiveWeapon()
	ply:BW_DropWeapon(Wep)
end, false)

util.AddNetworkString("CommandThing")

BaseWars.Commands.AddCommand({"discord", "dis", "dc"}, function(ply)
	net.Start("CommandThing")
		net.WriteUInt(0, 4)
	net.Send(ply)
end, false)

BaseWars.Commands.AddCommand({"content", "servercontent", "workshop"}, function(ply)
	net.Start("CommandThing")
		net.WriteUInt(1, 4)
	net.Send(ply)
end, false)

