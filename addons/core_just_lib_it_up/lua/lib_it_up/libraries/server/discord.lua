require("bromsock")

local quipchance = 5

local quips = {
	[[♂ COME ♂ ON ♂ LET'S ♂ GO ♂]],
	"Oh shit, I'm sorry",
	"Sorry for what?"
}

discord = discord or {}

--if discord.Enabled wasn't set, gets set to true
--otherwise, keeps value

discord.Enabled = (discord.Enabled == nil and true--[[jit.os:find("Windows")]]) or discord.Enabled

dissocket = dissocket or BromSock()


local log
local logtbl = {name = "Discord Relay", col = Color(40, 135, 255)}

if Modules and Modules.Log then
	log = function(str, ...)
		Modules.Log(logtbl, str:format(...))
	end

	discord.Log = log
end

hook.Add("PostGamemodeLoaded", "inventory_log", function()
	log = function(str, ...)
		Modules.Log(logtbl, str:format(...))
	end

	discord.Log = log
end)

local socket = dissocket

local pingport = 27025

local silence = false

discord.IP = Settings.GetStored("DiscordIP") or game.GetIPAddress():match("(.+):%d+$")
discord.Port = tonumber(Settings.GetStored("DiscordPort") or game.GetIPAddress():match(".+:(%d+)$"))

local function socketConnect(sock, connected, ip, port)

	if (not connected) then
		msg = "Unable to connect to Discord relay @ %s:%s.\n"
		msg = msg:format(ip, port)

		if not silence then MsgC(Color(250, 100, 100), msg) end

		return
	end

	msg = "Connected to Discord relay @ %s:%s!\n"
	msg = msg:format(ip, port)

	if not silence then MsgC(Color(100, 250, 100), msg) end

	socket:ReceiveUntil("\r\n");
end
socket:SetCallbackConnect(socketConnect);

local function sockDisconnect(sock)
	MsgC(Color(250, 100, 100), "Disconnected from IRC server.\n",
		"Type discord_reconnect or DiscordReconnect() to attempt reconnection.\n",
		"Right now, listening for messages.\n")

	sock:Listen(discord.IP, discord.Port)
	sock:SetCallbackConnect(socketConnect)
end
socket:SetCallbackDisconnect(sockDisconnect);

local function socketReceive(sock, packet)

	local full = packet:ReadLine():Trim()
	local r, g, b = full:match("(%d+),(%d+),(%d+)|")
	r, g, b = tonumber(r), tonumber(g), tonumber(b)

	full = full:gsub("%d+,%d+,%d+|", "")

	local col = Color(r, g, b)

	local name = full:match("(.+[^\\|])|")

	full = full:gsub("(.+[^\\|])|", "")

	ChatAddText(Color(70, 110, 220), "[Discord] ", col, name, Color(230, 230, 230), ": " .. full)
	MsgC(Color(70, 110, 220), "[Discord] ", col, name, Color(230, 230, 230), ": " .. full .. "\n")

	socket:ReceiveUntil("\r\n")
end

socket:SetCallbackReceive(socketReceive);



function DiscordReconnect()
	socket:Close()
	local ok = socket:Connect(discord.IP, discord.Port)
	if not ok then
		MsgC(Color(250, 100, 100), "Failed to connect to " .. discord.IP .. ":" .. discord.Port, "\n	",
			socket:GetLastError())
	else
		print("connected discord :)")
	end
end

concommand.Add("discord_reconnect", function(ply)
	if IsValid(ply) and not ply:IsSuperAdmin() then return end
	DiscordReconnect()
end)

--matches everything after a !, ., / until a first space
local cmdptrn = "^[%./!](%w+)%s?"

hook.NHAdd("PlayerSay", "Discord", function(ply, msg)
	if not discord.Enabled then return end
	if not discord.DB then return end

	local cmd = msg:match(cmdptrn)

	if 	aowl.cmds[cmd] or
		CUM.cmds[cmd] or
		BaseWars.Commands.cmds[cmd] or
		isfunction(ULib[cmd]) --ulib has a very gay method of storing commands
	then return end

	discord.Send("chat", ply:Nick(), msg)

end)

Embed = {}

EmbedMeta = {}
EmbedMeta.IsEmbed = true

EmbedMeta.__index = EmbedMeta

function EmbedMeta:SetTitle(txt, ...)
	self.title = txt:format(...)
	return self
end

EmbedMeta.SetName = EmbedMeta.SetTitle

function EmbedMeta:SetText(txt, ...)
	self.description = txt:format(...)
	return self
end

EmbedMeta.SetDescription = EmbedMeta.SetText

function EmbedMeta:SetColor(col, g2, b2)
	local r, g, b

	if IsColor(col) then
		r, g, b = col.r, col.g, col.b
	else
		r, g, b = col, g2, b2
	end

	self.color = bit.lshift(r, 16) + bit.lshift(g, 8) + b

	return self
end

function EmbedMeta:GetColor()
	return Color(bit.rshift(self.color, 16), bit.rshift(self.color % 2^16, 8), self.color % 2^8)
end
function Embed:new()
	local t = {}
	setmetatable(t, EmbedMeta)

	return t
end


Embed.__call = Embed.new

setmetatable(Embed, Embed)


local db

if not mysqloo then include("mysql.lua") end

mysqloo.UseLiveDB():Then(function(self, db2)
	print("discord: livedb connected")
	db = db2
	discord.DB = db2
end, error)

function discord.GetChannels(mode, cb)
	local q = "SELECT whook_url FROM `relays` WHERE json_search(`modes`, 'one', '%s') IS NOT NULL"
	q = q:format(db:escape(mode))

	local q = db:query(q)

	q.onSuccess = function(self, dat)
		local urls = {}

		if not dat[1] then return end --no relays listening for this mode

		for k,v in pairs(dat) do
			urls[#urls + 1] = v.whook_url
		end

		cb(urls)
	end

	q.onError = function(self, err, sql)
		log("Error on attempting to get channels.\nError: %s\nSQL: %s", err, sql)
	end

	q:start()
end

function discord.Send(mode, name, txt)

	local function callback(urls)

		http.Post("https://vaati.net/Gachi/shit.php", {
			name = name or "lodestar/generic",
			api = "disrelay",
			p = txt,
			json = "y",
			chan = util.TableToJSON(urls),
		})

	end

	discord.GetChannels(mode, callback)
end

function discord.SendUnescaped(mode, name, txt)

	local function callback(urls)

		http.Post("https://vaati.net/Gachi/shit.php", {
			name = name or "lodestar/generic",
			api = "disrelay",
			p = txt,
			json = "y",
			chan = util.TableToJSON(urls),
			noescape = "y",
		})

	end

	discord.GetChannels(mode, callback)
end

BlankFunc = function(...) end

function discord.SendEmbed(mode, name, t, cb, fail)
	local em

	if t.IsEmbed then
		em = {t}
	else
		em = t
	end

	local function callback(urls)
		http.Post("https://vaati.net/Gachi/shit.php", {
			name = name or "lodestar/generic",
			api = "disrelay",
			json = "y",
			chan = util.TableToJSON(urls),
			embeds = util.TableToJSON(em),
		}, cb or BlankFunc, fail or BlankFunc)
	end

	discord.GetChannels(mode, callback)
end


discord.Notified = discord.Notified or false

discord.Notified = true --disabled notifications for now

hook.Add("Tick", "ServerNotify", function()

	if discord.Notified then return end

	RunConsoleCommand("sv_hibernate_think", 1)

	local quip

	local pass = math.random(0, 100) < quipchance

	if pass then

		while quip == nil do
			quip = eval(quips[math.random(#quips)])
		end

		quip = quip .. "\n\n"	--if we should generate a quip, add newlines
	else
		quip = ""
	end




	discord.Notified = true

	timer.Simple(10, function()
		local em = Embed()
		local desc = quip .. "Join @ steam://connect/" .. game.GetIPAddress() .. " !"	--gmod pls

		  em:SetTitle("Server is now online!")
			:SetDescription(desc)
			:SetColor(Color(100, 230, 100))

		discord.SendEmbed("status", nil, em, function(...)

			RunConsoleCommand("sv_hibernate_think", 0)
			hook.Remove("Tick", "ServerNotify")

		end, function(...)

			RunConsoleCommand("sv_hibernate_think", 0)
			hook.Remove("Tick", "ServerNotify")
		end)

	end)

end)