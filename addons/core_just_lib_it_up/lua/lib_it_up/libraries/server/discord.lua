require("gwsockets")

local quipchance = 5

local quips = {
	[[♂ COME ♂ ON ♂ LET'S ♂ GO ♂]],
	"Oh shit, I'm sorry",
	"Sorry for what?"
}

discord = discord or {}
discord.Socket = discord.Socket

--if discord.Enabled wasn't set, gets set to true
--otherwise, keeps value

discord.Enabled = (discord.Enabled == nil and true--[[jit.os:find("Windows")]]) or discord.Enabled


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

local silence = false

local function socketConnect(_, sock)
	local msg = "Connected to Discord relay @ %s!\n"
	msg = msg:format(sock.url)

	if not silence then
		MsgC(Color(100, 250, 100), msg)
	end
end

local function socketFailConnect(_, sock, err)
	local msg = "Unable to connect to Discord relay @ %s.\n" ..
		"	Error: %s\n" ..
		"	Type discord_reconnect or DiscordReconnect() to attempt reconnection.\n"

	msg = msg:format(sock.url, err)

	if not silence then
		MsgC(Color(250, 100, 100), msg)
	end

	sock.planned = true
end

local function sockDisconnect(sock)
	if sock.planned then return end

	MsgC(Color(250, 100, 100), "Disconnected from IRC server.\n",
		"Type discord_reconnect or DiscordReconnect() to attempt reconnection.\n")
end

local function socketReceive(sock, str)
	if not discord.Enabled then return end

	local r, g, b = str:match("^(%d+),(%d+),(%d+)|")
	r, g, b = tonumber(r), tonumber(g), tonumber(b)

	if not r or not g or not b then
		print("received incorrect discord relay format (no color) - ignoring")
		printf("%d: ( %s )", #str, str)
		return
	end

	str = str:gsub("^%d+,%d+,%d+|", "")

	local col = Color(r, g, b)

	local nameLen = tonumber(str:match("^(%d+)|"))
	if not nameLen then
		print("received incorrect discord relay format (no namelen) - ignoring")
		printf("%d: ( %s )", #str, str)
		return
	end

	str = str:gsub("^%d+|", "")

	local name = str:sub(1, nameLen)
	local msg = str:sub(nameLen + 1)

	ChatAddText(Color(70, 110, 220), "[Discord] ", col, name, Color(230, 230, 230), ": " .. msg)
	-- MsgC(Color(70, 110, 220), "[Discord] ", col, name, Color(230, 230, 230), ": " .. msg .. "\n")
end

function DiscordReconnect()
	discord.IP = Settings.GetStored("DiscordIP") or game.GetIPAddress():match("(.+):%d+$")
	discord.Port = tonumber(Settings.GetStored("DiscordPort") or game.GetIPAddress():match(".+:(%d+)$"))

	if discord.Socket then
		discord.Socket.planned = true
		discord.Socket:close()
	end

	discord.Socket = GWSockets.createWebSocket("ws://" .. discord.IP .. ":" .. discord.Port,
		false)

	local sock = discord.Socket
	sock.url = "ws://" .. discord.IP .. ":" .. discord.Port

	local pr = Promise()
	sock.onError = pr:Rejector()
	sock.onConnected = pr:Resolver()

	pr:Then(socketConnect, socketFailConnect)

	sock:open()
	sock.onMessage = socketReceive
	sock.onDisconnected = sockDisconnect
end

concommand.Add("discord_reconnect", function(ply)
	if IsValid(ply) and not ply:IsSuperAdmin() then return end
	DiscordReconnect()
end)

DiscordReconnect()

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

	msg = discord.Escape(msg)
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

if not mysqloo then
	include("mysql.lua")
end

mysqloo.UseLiveDB():Then(function(self, db2)
	db = db2
	discord.DB = db2
end, error)

function discord.GetChannels(mode, cb)
	local q = "SELECT whook_url FROM `relays` WHERE json_search(`modes`, 'one', '%s') IS NOT NULL"
	q = q:format(db:escape(mode))

	local em = MySQLQuery(db:query(q), true)
		:Then(function(_, self, dat)
		local urls = {}

		if not dat[1] then return end --no relays listening for this mode

		for k,v in pairs(dat) do
			urls[#urls + 1] = v.whook_url
		end

		if cb then cb(urls) end
	end)

	return em
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

function discord.Escape(str)
	str = str:gsub("@everyone", "(at)everyone")
		:gsub("@here", "(at)here")
		:gsub("@", "\\@")

	return str
end

local sendQueue = muldim:new()

local function flush()
	for chan, names in pairs(sendQueue) do
		local embeds = {}

		for name, ems in pairs(names) do
			for _, em in ipairs(ems) do
				embeds[#embeds + 1] = em
			end
		end

		discord.SendEmbed(chan, name, embeds)
	end

	table.Empty(sendQueue)
end

function discord.QueueEmbed(chan, name, em)
	sendQueue:Insert(em, chan, name)

	if not timer.Exists("DiscordFlush" .. name) then
		timer.Create("DiscordFlush" .. name, 0.5, 1, flush)
	end
end