local TitleColor = Color(225, 225, 225, 175)
local enabled = CreateClientConVar( "titles_enabled", "1", true, false, "Enable players' names and titles above their heads?\nIf this is set to 0, a 2D alternative(less performance-tanking) way will be used." )
local playertitles = PlayerTitles or {}

local Title = {}
Titles = {}

PlayerTitles = playertitles


--dude this is top tier
--obfuscation via shit coding skills OMEGALUL

surface.CreateFont("TitleName", {
	font = "Helvetica",
	size = 128,
	weight = 600,
	antialias = true,
	})

surface.CreateFont("TitleNameRound", {
	font = "Helvetica",
	size = 128,
	weight = 600,
	blursize = 8,
	antialias = false,
	shadow = true,
})

surface.CreateFont("Status", {
	font = "Helvetica",
	size = 48,
	weight = 600,
	antialias = true,
	})

surface.CreateFont("StatusShadow", {
	font = "Helvetica",
	size = 48,
	weight = 600,
	blursize = 8,
	antialias = false,
	shadow = true,
})

surface.CreateFont("Title", {
	font = "Roboto Light",
	size = 72,
	weight = 400,
	blursize = 0,
	antialias = true,
	--shadow = true,
	})

local emoticon_cache = ChatHUDEmoticonCache or {}
local busy = {}

local PLAYER = debug.getregistry().Player

function PLAYER:GetTitle()
	return self:GetNWString("Title", nil)
end

local FFZChannels = {
	"pajlada",
	"1poseidon3",
	"forsen",
	"benignmc",
	"clay0m",
	"amberg22",
	"tomatobird8"
}

local EmoteShortcuts = {}
local EmoteSize = {}
TitleEmotes = EmoteShortcuts

file.CreateDir("emoticon_cache")
file.CreateDir("emoticon_cache/ffz")

local function CreateFFZShortcuts(update)

		local function DownloadChannelInfo(chan)
			local chan = string.lower(chan)
			local filename = "emoticon_cache/ffz_global_emotes_" .. chan .. ".dat"
			Msg("[NT]: FFZ data for channel "..chan.." not found! Downloading... \n")

				http.Fetch("https://api.frankerfacez.com/v1/room/"..tostring(chan), function(b)
					local d = util.JSONToTable(b)
					if not d then return ErrorNoHalt("[NT]: Failed to update FFZ Emote cache.\n") end

					for name1, v in pairs(d) do
						--if isnumber(v) then continue end

						if name1=="sets" then
							for k,_ in pairs(v) do --i hate it as much as you do
								name=_
							end
						continue
						end

					end

					if istable(name["emoticons"]) then
						for num, cont in pairs(name["emoticons"]) do
								if (cont.name) and not EmoteShortcuts[cont.name] then
									local url
									if cont.urls[4] then url=cont.urls[4] elseif cont.urls[2] then url=cont.urls[2] else url=cont.urls[1] end
									EmoteShortcuts[cont.display_name or cont.name] = string.Replace( url, "//cdn.frankerfacez.com/", "" )
								end

						end
					end

						if !file.Exists(filename, "DATA") then
							file.Write(filename, "")
							file.Append(filename, b .. " " )
						else
							file.Append(filename, b .. " " )
						end

				end, function() print("send help") end)
		end

		local function ReadChannelInfo(filename, chan)

		filename = string.lower(filename)
		Msg("[NT]: FFZ data file found! Creating emote shortcuts... \n")
			if file.Exists(filename, "DATA") and not update then
				local data = file.Read(filename, "DATA")
				local d = util.JSONToTable(data)
				if not d then
					file.Delete(filename)
					DownloadChannelInfo(chan)
					return ErrorNoHalt("[NT]: Failed to read existing FFZ Emote cache. Deleting and attempting redownload...\n")
				end

				local name
				for name1, v in pairs(d) do
					if name1=="sets" then
						for k,_ in pairs(v) do --i hate it as much as you do
							name=_
						end
						continue
					end
				end

				if not name then return end

				if istable(name["emoticons"]) then
					for num, cont in pairs(name["emoticons"]) do
							if (cont.name) and not EmoteShortcuts[cont.name] then
								local url
								if cont.urls[4] then url=cont.urls[4] elseif cont.urls[2] then url=cont.urls[2] else url=cont.urls[1] end

								EmoteShortcuts[cont.display_name or cont.name] = string.Replace( url, "//cdn.frankerfacez.com/", "" )
								EmoteSize[cont.display_name or cont.name] = {cont.width or 32, cont.height or 32}
							end

					end
				end
			end
		end

		local found = file.Find("emoticon_cache/ffz_global_emotes_*.dat", "DATA")

		for k,chan in pairs(FFZChannels) do
			if table.HasValue(found,"ffz_global_emotes_"..string.lower(chan)..".dat") then
				ReadChannelInfo("emoticon_cache/ffz_global_emotes_"..string.lower(chan)..".dat", string.lower(chan))
			else
				DownloadChannelInfo(string.lower(chan))
			end

		end

end
CreateFFZShortcuts()

local function MakeCache(filename, emoticon, id)
	local mat = Material("data/" .. string.lower(filename), "noclamp smooth")
	emoticon_cache[id] = mat
end

local function GetFFZEmoticon(emoticon)
	local id = emoticon:match("/?(%d+)/?") .. ".png"

	if emoticon_cache[id] then
		return emoticon_cache[id]
	end
	if busy[id] then
		return false
	end

	if file.Exists("emoticon_cache/ffz/" .. id, "DATA") then
		MakeCache("emoticon_cache/ffz/" .. id, emoticon, id)
		return emoticon_cache[id] or false
	end

	http.Fetch("https://cdn.frankerfacez.com/" .. emoticon, function(body, len, headers, code)
		if code == 200 then
			if body == "" then
				print("Titles FFZ: Server returned OK but empty response")
				return
			end

			file.Write("emoticon_cache/ffz/" .. id, body)
			MakeCache("emoticon_cache/ffz/" .. id, emoticon, id)
		else
			Msg"NT " print("Download failure. Code: " .. code)
		end
	end, function() print("why emote dead wtf????") end)
	busy[emoticon] = true
	return false
end

local function ParseTitle(txt)

	local tags = {}

	for i=1, 6 do --up to 6 tags

		 local tag = string.match(txt,"%b<>")
		 if tag then

			local pos1, pos2 = string.find(txt, tag, 1, true)
			if not pos1 or not pos2 then continue end

			txt = string.sub( txt, 1, pos1 - 1 ) .. string.sub( txt, pos2 + 1 )

			table.insert(tags, {[1] = tag, [2] = pos1})
		 end

	end

	return tags, txt
end

function PLAYER:UpdateTitle()
	local title = self:GetNWString("Title", false)
	if not self:SteamID64() then return end
	if title and isstring(title) then
		playertitles[self:SteamID64()] = title
	end

end

local ModColor = TitleColor
local TextTranslate = {0,0}


local function env()
	local tick = 0
	return {
		sin = math.sin,
		cos = math.cos,
		tan = math.tan,
		sinh = math.sinh,
		cosh = math.cosh,
		tanh = math.tanh,
		rand = math.random,
		min = math.min,
		abs = math.abs,
		max = math.max,
		pi = math.pi,
		log = math.log,
		log10 = math.log10,
		time = CurTime,
		t = CurTime,
		realtime = RealTime,
		rt = RealTime,
		tick = function()
			local o = tick
			tick = tick + 1
			return o / 100
		end,
	}
end

local badlua = {
	["while"] = true,
	["for"] = true,
	["do"] = true,
	["end"] = true,
	["if"] = true
}

function Title:CompileExpression(expression)
	local env = env()
	local ch = expression:match("[^=1234567890%-%+%*/%%%^%(%)%.A-z%s]")	--match anything that is not a letter, a math symbol(+, -, %, /, ^, etc.) or a number

	if ch then 	--disallow strings and string methods ( e.g. ("Stinky poopy"):rep(999) )
				--fun fact; the string library may not be in the envinroment but string methods will still work!
		return "expression: invalid character " .. ch
	end

	for word in expression:gmatch("(.-)%s") do
		if badlua[word] then return "simple expressions please" end
	end

	local compiled = CompileString("return (" .. expression .. ")", "expression", false)
	if isstring(compiled) then
		compiled = CompileString(expression, "expression", false)
	end
	if isstring(compiled) then
		return compiled
	end
	if not isfunction(compiled) then
		return "expression:1: unknown error"
	end
	setfenv(compiled, env)
	return compiled
end



function Title:TextPos(tbl)
	local x = tonumber(tbl[1]) or 0
	local y = tonumber(tbl[2]) or 0
	x = math.Clamp(x, -300, 300)
	y = math.Clamp(y, -200, 200)
	TextTranslate = {x, y}
	self.modX, self.modY = x, y
end


function Title:Emote(txt)
	local txt, sx, sy = unpack(txt)
	local oldtxt = txt
	if EmoteShortcuts[txt] then
		txt = EmoteShortcuts[txt]
		local fonty = self.fontY or 32
		if not isstring(txt) then return end

		local mat = GetFFZEmoticon(txt)
		if not mat or mat:IsError() then return end
		local pref = ((tonumber(sx) and tonumber(sy)) and {tonumber(sx), tonumber(sy)}) or EmoteSize[oldtxt]
		local ex, ey = unpack(pref or {32, 32})
		ex = math.Clamp(ex, -128, 128)
		ey = math.Clamp(ey, -64, 64)
		surface.SetMaterial(mat)
		surface.SetDrawColor(255,255,255,(self.cra or 255))
		local x = self.x - self.textsize/2 + (self.modX or 0)

		surface.DrawTexturedRect(x, fonty*1.5-tonumber(ey*1.5)+(self.modY or 0), tonumber(ex*3), tonumber(ey*3))
		self.x = (self.x or 0) + ex*3 + 12

	 end

end

function Title.TextColor(self, col)
	local curc = self.TextColorMod or {}
	if col then
		local r, g, b = tonumber(col[1]), tonumber(col[2]), tonumber(col[3])
		r, g, b = math.Clamp(r or 0, 0, 255), math.Clamp(g or 0, 0, 255), math.Clamp(b or 0, 0, 255)		--so the user doesn't have to deal with wrapping

		local c = Color(r, g, b, tonumber(col[4]) or curc.a or 255)
		self.TextColorMod = c or Color(205,205,205, curc.a or 255)
	else
		self.TextColorMod = Color(205,205,205, curc.a or 255)
	end
end

function Title:HSV(col)
	local curc = self.TextColorMod
	if col then
		local hsv = HSVToColor((tonumber(col[1]) or 0)%360, tonumber(col[2]) or 1, tonumber(col[3]) or 1)
		hsv.a = curc.a or 255
		self.TextColorMod = hsv or Color(205,205,205, curc.a or 255)
	else
		self.TextColorMod = Color(205,205,205,  curc.a or 255)
	end

end

local myPos = Vector(0,0,0)
local UpdatedViaCam = false

local actions = {

	["color"] = Title.TextColor,
	["translate"] = Title.TextPos,
	["emote"] = Title.Emote,
	["hsv"] = Title.HSV,
}
local onetags = {

	["emote"] = true,

}

hook.Add("RenderScene", "TitlesCalcView", function(pos, ang)
		myPos   = pos
		UpdatedViaCam = true
end)


local ErroredTitles = {}
local ErroredTitlesStr = {}

local cra = {}  --crouch alpha, yes, very explanatory and obvious
local afk = {}
local hps = {}
local ARs = {}

surface.CreateFont("TitleName2d", {
	font = "Helvetica",
	size = 64,
	weight = 600,
	antialias = true,
	})

surface.CreateFont("TitleNameRound2d", {
	font = "Helvetica",
	size = 64,
	weight = 600,
	blursize = 8,
	antialias = false,
	shadow = true,
})


surface.CreateFont("Title2d", {
	font = "Roboto Light",
	size = 36,
	weight = 400,
	blursize = 0,
	antialias = true,
	--shadow = true,
})

local ARAlpha = 255

local drawn = setmetatable({}, {__mode = "kv"})

function Titles.Draw(ply)
	if not enabled:GetBool() then return false end
	if drawn[ply] == FrameNumber() then return false end
	drawn[ply] = FrameNumber()
	ply:UpdateTitle()
	local me = LocalPlayer()
	local sid = ply:SteamID64() or ply:UserID()

	local pos = me:GetPos()
	if pos:DistToSqr(ply:GetPos()) > 1048576 then return end --1024 ^ 2
	if UpdatedViaCam then
		pos = myPos
	end

	local vec = ( ply:GetPos() - pos ):GetNormalized()

	local ang = vec:Angle() - Angle(0,90,0)



	--ang:RotateAroundAxis(ang:Right(), 90)
	ang:RotateAroundAxis(ang:Forward(), 90)
	ang.p = 0
	--ang:RotateAroundAxis(ang:Up(), 90)

	local pos = Vector(0,0,0) --ply:GetPos() + Vector(0, 0, 80) + ply:GetAngles():Forward()*1
	local eyesid = ply:LookupAttachment('eyes')
	local eyeang = ply:EyeAngles()
	eyeang.r = 0
	if eyesid <= 0 then
		pos = ply:GetPos() + Vector(0, 0, 80) + eyeang:Forward()*3 --alternative way of getting pos
	else
		local eyepos = ply:GetAttachment(eyesid)
		local fwd = eyeang:Forward()
		fwd.z = 0
		pos = (eyepos.Pos + Vector(0, 0, 20) + fwd*-3) or (ply:GetPos() + Vector(0, 0, 80) + fwd*3) -- this as well

	end

	local scale = 0.05

	local tags = {}
	local x = 0


	if ply:GetNW2Int("AFK", 0) ~= 0 and CurTime() - ply:GetNW2Int("AFK", 0) > 30 then
		afk[sid] = true
	else
		afk[sid] = false
	end

	cam.Start3D2D(pos, ang, scale)

		if ply:Crouching() then
			cra[sid] = Lerp(FrameTime()*10, (cra[sid] or 10), 10)
		else
			cra[sid] = Lerp(FrameTime()*5, (cra[sid] or 200), 200)
		end
		hps[sid] = Lerp(FrameTime()*5, (hps[sid] or ply:GetMaxHealth()), math.min(ply:Health(), ply:GetMaxHealth()))

		local maxHp = ply:GetMaxHealth()

		local bw = 600*(hps[sid]/maxHp)
		local bx = -300
		local y = 180
		local bh = 30
		local slant = 16
		local a = cra[sid]

		y = y + 40
		bh = 30
		bx = bx - slant
		ARs[sid] = Lerp(FrameTime()*5, (ARs[sid] or 0), math.min(ply:Armor(), 200))

		bw = 600 * (ARs[sid]/200)-- - slant

		local arCol = 9
		local arColL = 9

		local pln = string.gsub(ply:Name(), "#", "")

		surface.SetFont("TitleNameRound")   --blur
		local s = surface.GetTextSize(pln)
		surface.SetTextPos( 0 - s/2, -50 )	--ok?
		surface.SetTextColor(0, 0, 0, cra[sid])

		surface.DrawText(pln)

		surface.SetFont("TitleName")
		surface.SetTextPos( 0 - s/2, -50 )	--ok?
		surface.SetTextColor(ColorAlpha(team.GetColor(ply:Team()), cra[sid]))

		surface.DrawText(pln)

		--if afk[sid]]then
		if ply:GetNW2Bool("IsAFK") then
			local afktxt = "AFK for "
			local tabbed = ( ply:GetNW2Bool("AFKFocused", true) and "") or " (tabbed out)"
			local timetxt = string.NiceTime(CurTime() - ply:GetNW2Float("AFK", 0)) .. tabbed .. "..."
			surface.SetFont("Status")
			local statuss = surface.GetTextSize(afktxt) + surface.GetTextSize(timetxt)
			local timex = surface.GetTextSize(afktxt)

			surface.SetFont("Status")
			surface.SetTextPos( 0 - statuss/2, -90 )	--ok?
			surface.SetTextColor(Color(160,80,190))

			surface.DrawText(afktxt)

			surface.SetTextPos( 0 - statuss/2 + timex, -90 )	--ok?
			surface.SetTextColor(Color(140,220,140))

			surface.DrawText(timetxt)


			surface.SetFont("StatusShadow")
			surface.SetTextPos( 0 - statuss/2, -90 )	--ok?
			surface.SetTextColor(Color(0,0,0,200))

			surface.DrawText(afktxt)
		end
		if playertitles[sid] then

			Title.Player = {}
			local self = Title.Player
			self.x = 0

			self.cra = cra[sid]

			local tag, title = ParseTitle(playertitles[sid])
			self.text = title


			for k,v in pairs(tag) do
				local tag = v[1]
				local pos = v[2]

				tag = string.sub(tag, 2, #tag - 1)

					local op = string.match(tag, "^([%a]+)=")
					if not op then
						op = string.match(tag, "^(/[%a]+)")
						if not op then continue end
					end

					local args = string.sub(tag, #op+2, #tag)
					args = string.Explode(",", args)

					if not istable(args) or #args == 0 then continue end
					table.insert(tags, {op, pos, args})

			end


			--tags:
				--1: tag name
				--2: position in text
				--3: arguments

			surface.SetFont("Title")
			local fontx, fonty = surface.GetTextSize("A")

			self.fontY = fonty

			local fullx = surface.GetTextSize(title)
			for k,v in pairs(tags) do

				if v[1] == "emote" then

					local ex, ey = unpack(EmoteSize[unpack(v[3])] or {32, 32})
					fullx = fullx+ex*3+8
				end

			end

			self.textsize = fullx


			local activetags = {}

			for t=1, #title+1 do

				local txt = title[t]

				local tx = surface.GetTextSize(txt)
				self.x = self.x + tx
				self.char = t
				for k,v in pairs(tags) do

					local op = v[1]
					local pos = v[2]
					local args = v[3]



					if t>=pos then
						if op[1]~="/" then
							activetags[op] = {pos, args}
						else
							op = string.sub(op, 2, #op)
							activetags[op] = nil
						end
					end
				end

				local i=0

				Title.TextColor(self)

				for k,v in pairs(activetags) do
					if not v then continue end

					local pos = v[1]
					local args = v[2]
					local endpos = v[3] or 0

						for k,v in pairs(args) do
							local exp = string.match(v, "%b[]")

							if exp and #exp > 2 then
								exp = string.sub(exp, 2, #exp-1)
								local compiled = Title.CompileExpression(self, exp)
								local ok, ret

								if isfunction(compiled) then
									ok, ret = pcall(compiled)
								end

								if ok and tonumber(ret) then args[k] = tonumber(ret) end

								if not ok then
									if ply==LocalPlayer() then
										if not ErroredTitles[playertitles[sid]] or not ErroredTitlesStr[exp] then
											print('Your title is erroring out.\n', ret)
											ErroredTitles[playertitles[sid]] = true
											ErroredTitlesStr[exp] = true
										end
									end
								end

							end
						end

					if actions[k] and not onetags[k] then

						actions[k](self, args)

					elseif onetags[k] and (pos>=t) then

						actions[k](self, args)
						activetags[k] = nil

					end
				end


				local PosModX, PosModY = TextTranslate[1], TextTranslate[2]
				local x = self.x

				surface.SetTextColor(self.TextColorMod or Color(205, 205, 205))

				surface.SetTextPos( x - tx - fullx/2 + PosModX, 80 + PosModY )	--ok?

				surface.DrawText(txt)

				surface.SetTextColor(Color(10,10,10, 40))

				surface.SetTextPos( x - tx - fullx/2 + 2 + PosModX, 81 + PosModY )

				surface.DrawText(txt)

				TextTranslate = {0, 0}
			end

		else
			ply:UpdateTitle()
		end
		--surface.DrawText( ply:Nick() )

	cam.End3D2D()

end


function Titles.DrawNonPlayer(title, color, name, pnl, x, y, font1)


	local tags = {}
	local pnlX = x
	local pnlY = y
	local pln = (name or "<no name>"):gsub("#", "")
	local err = nil
	local fulltextwidth = 0

	local a = color.a or 255

	local font = font1 or "Title2d"

	if name then
		draw.SimpleText(pln, "TitleNameRound2d", 0+pnlX, -80+pnlY, Color(0,0,0,255), 1, 0)
		draw.SimpleText(pln, "TitleName2d", 0+pnlX, -80+pnlY, color or Color(60,60,60), 1, 0)
	end

		if title then

			Title.Player = {}
			local self = Title.Player
			self.x = pnlX

			self.cra = 255

			local tag, title = ParseTitle(title)
			self.text = title


			for k,v in pairs(tag) do
				local tag = v[1]
				local pos = v[2]

				tag = string.sub(tag, 2, #tag - 1)

					local op = string.match(tag, "^([%a]+)=")
					if not op then
						op = string.match(tag, "^(/[%a]+)")
						if not op then continue end
					end

					local args = string.sub(tag, #op+2, #tag)
					args = string.Explode(",", args)

					if not istable(args) or #args == 0 then continue end
					table.insert(tags, {op, pos, args})

			end


			--tags:
				--1: tag name
				--2: position in text
				--3: arguments

			surface.SetFont(font)
			local fontx, fonty = surface.GetTextSize("A")

			self.fontY = fonty

			local fullx = surface.GetTextSize(title)
			for k,v in pairs(tags) do

				if v[1] == "emote" then

					local ex, ey = unpack(EmoteSize[unpack(v[3])] or {32, 32})
					fullx = fullx+ex*3+8
				end

			end

			self.textsize = fullx


			local activetags = {}

			for t=1, #title+1 do

				local txt = title[t]

				local tx = surface.GetTextSize(txt)
				self.x = self.x + tx
				self.char = t
				for k,v in pairs(tags) do

					local op = v[1]
					local pos = v[2]
					local args = v[3]



					if t>=pos then
						if op[1]~="/" then
							activetags[op] = {pos, args}
						else
							op = string.sub(op, 2, #op)
							activetags[op] = nil
						end
					end
				end

				local i=0
				--Title.TextColor(self)
				self.TextColorMod = Color(205, 205, 205, a)
				for k,v in pairs(activetags) do
					if not v then continue end

					local pos = v[1]
					local args = v[2]
					local endpos = v[3] or 0

						for k,v in pairs(args) do

							local exp = string.match(v, "%b[]")

							if exp and #exp > 2 then
								exp = string.sub(exp, 2, #exp-1)
								local compiled = Title.CompileExpression(self, exp)
								local ok, ret

								if isfunction(compiled) then
									ok, ret = pcall(compiled)
								end
								--print(compiled, ok, ret)

								if ok and tonumber(ret) then args[k] = tonumber(ret) end

								if not ok then
									local errstr = ""

									if isstring(compiled) then errstr=compiled else errstr=ret end

									if not ErroredTitlesStr[exp] then
										print('Your title is erroring out.\n', errstr)
										ErroredTitlesStr[exp] = true
									end

									err = errstr
									return fullx, err

								end

							end
						end

					if actions[k] and not onetags[k] then

						actions[k](self, args)
					elseif onetags[k] and (pos>=t) then

						actions[k](self, args)
						activetags[k] = nil

					end
				end
				local PosModX, PosModY = TextTranslate[1], TextTranslate[2]
				local x = self.x

				local textX = x - tx - fullx/2 + PosModX

				surface.SetTextColor(self.TextColorMod or Color(205, 205, 205, a))

				surface.SetTextPos( textX, -10 + PosModY + pnlY )	--ok?

				surface.DrawText(txt)

				surface.SetTextColor(Color(10,10,10, a/10))

				surface.SetTextPos( x - tx - fullx/2 + 2 + PosModX, -10 + PosModY + pnlY)

				surface.DrawText(txt)

				TextTranslate = {0, 0}
			end

			return fullx, err
		end

end

hook.Add("PostPlayerDraw", "Titles", function(ply)
	Titles.Draw(ply)
end)

hook.Add("HUDDrawTargetID", "NoTargetID", function()
	if enabled:GetInt() ~= 0 then return false end
end)

PlayerTitles.Emotes = EmoteShortcuts