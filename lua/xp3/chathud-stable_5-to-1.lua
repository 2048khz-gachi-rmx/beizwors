file.CreateDir("emoticon_cache")

local col = Color(255, 200, 0, 255)
local Msg = function(...) MsgC(col, ...)  end
local surface = surface 

local utflen = function(s)
	return (utf8.len(s:sub(#s, #s-1)) == 1 and #(s:sub(#s, #s-1) == 2)) and 2 or 1
end

local Run = function(func, ...)	--kinda like eval
	if isfunction(func) then 
		return func(...)
	end
end

chathud = chathud or {}
chathud.oldShadow = chathud.oldShadow or false

--[[
	This chat is a piece of shit, so I removed every comment. So you don't poke around for too long and gouge your fucking eyes out.
	Enjoy.
]]

chathud.FFZChannels = {
	"pajlada",
	"1poseidon3",
	"forsen",
	"benignmc",
	"clay0m"
}

chathud.TagTypes = {
	["number"] = tonumber,
	["string"] = tostring,
}
chathud.PreTags = {
	["rep"] = {
		args = {
			[1] = {type = "number", min = 0, max = 10, default = 1},
		},
		func = function(text, args)
			return text:rep(args[1])
		end
	},
}

if string.anime then
	chathud.PreTags["anime"] = {
		args = {
			-- no args
		},
		func = string.anime
	}
end

chathud.Tags = {
	["color"] = {
		args = {
			[1] = {type = "number", min = 0, max = 255, default = 255}, -- r
			[2] = {type = "number", min = 0, max = 255, default = 255}, -- g
			[3] = {type = "number", min = 0, max = 255, default = 255}, -- b
			[4] = {type = "number", min = 0, max = 255, default = 255}, -- a
		},
		TagStart = function(self, markup, buffer, args)
			self._fgColor = buffer.fgColor
		end,
		ModifyBuffer = function(self, markup, buffer, args)
			buffer.fgColor = Color(args[1] or 255, args[2] or 255, args[3] or 255, args[4] or 255)
		end,
		TagEnd = function(self, markup, buffer, args)
			buffer.fgColor = self._fgColor or Color(255, 255, 255, 255)
			self._fgColor = nil
		end,
	},
	["bgcolor"] = {
		args = {
			[1] = {type = "number", min = 0, max = 255, default = 255}, -- r
			[2] = {type = "number", min = 0, max = 255, default = 255}, -- g
			[3] = {type = "number", min = 0, max = 255, default = 255}, -- b
			[4] = {type = "number", min = 0, max = 255, default = 0}, -- a
		},
		TagStart = function(self, markup, buffer, args)
			self._bgColor = buffer.bgColor
		end,
		ModifyBuffer = function(self, markup, buffer, args)
			buffer.bgColor = Color(args[1] or 255, args[2] or 255, args[3] or 255, args[4] or 255)
		end,
		TagEnd = function(self, markup, buffer, args)
			buffer.bgColor = self._bgColor or Color(255, 255, 255, 0)
		end,
	},
	
	["hsv"] = {
		args = {
			[1] = {type = "number", default = 0},					--h
			[2] = {type = "number", min = 0, max = 1, default = 1},	--s
			[3] = {type = "number", min = 0, max = 1, default = 1},	--v
		},
		TagStart = function(self, markup, buffer, args)
			self._fgColor = buffer.fgColor
		end,
		ModifyBuffer = function(self, markup, buffer, args)
			if not self._fgColor then self._fgColor = buffer.fgColor end
			buffer.fgColor = HSVToColor(args[1] % 360, args[2] or 1, args[3] or 1)
		end,
		TagEnd = function(self, markup, buffer, args)
			buffer.fgColor = self._fgColor or Color(255, 255, 255, 255)
		end,
	},
	["dev_hsvbg"] = {
		args = {
			[1] = {type = "number", default = 0},					--h
			[2] = {type = "number", min = 0, max = 1, default = 1},	--s
			[3] = {type = "number", min = 0, max = 1, default = 1},	--v
		},
		TagStart = function(self, markup, buffer, args)
			self._bgColor = buffer.bgColor
		end,
		ModifyBuffer = function(self, markup, buffer, args)
			buffer.bgColor = HSVToColor(args[1] % 360, args[2], args[3])
		end,
		TagEnd = function(self, markup, buffer, args)
			buffer.bgColor = self._bgColor or Color(255, 255, 255, 0)
		end,
	},
	["translate"] = {
		args = {
			[1] = {type = "number", default = 0},	-- x
			[2] = {type = "number", default = 0},	-- y
		},
		TagStart = function(self, markup, buffer, args)
			self.mtrx = Matrix()
		end,
		Draw = function(self, markup, buffer, args)
			self.mtrx:SetTranslation(Vector(args[1], args[2]))
			cam.PushModelMatrix(self.mtrx)

		end,
		TagEnd = function(self)
			cam.PopModelMatrix()
		end,
	},
	["rotate"] = {
		args = {
			[1] = {type = "number", default = 0},	-- y
		},
		TagStart = function(self, markup, buffer, args)
			self.mtrx = Matrix()
		end,
		Draw = function(self, markup, buffer, args)
			--self.mtrx:SetTranslation(Vector(0, 0))

			self.mtrx:Translate(Vector(buffer.x, buffer.y + (buffer.h * 0.5)))
				self.mtrx:SetAngles(Angle(0, args[1], 0))
			self.mtrx:Translate(-Vector(buffer.x, buffer.y + (buffer.h * 0.5)))
			cam.PushModelMatrix(self.mtrx)
		end,
		TagEnd = function(self)
			cam.PopModelMatrix()
		end,
	},
	["scale"] = {
		args = {
			[1] = {type = "number", default = 1, max = 3},	-- x
			[2] = {type = "number", default = 1, max = 3},	-- y
		},
		TagStart = function(self, markup, buffer, args)
			self.mtrx = Matrix()
			self._bufferx = buffer.x
			self._buffery = buffer.y
		end,
		Draw = function(self, markup, buffer, args)
			--self.mtrx:SetTranslation(Vector(0, 0))

			self.mtrx:Translate(Vector(buffer.x, buffer.y + (buffer.h * 0.5)))
				self.mtrx:Scale(Vector(args[1], args[2]))
			self.mtrx:Translate(-Vector(buffer.x, buffer.y + (buffer.h * 0.5)))
			
			cam.PushModelMatrix(self.mtrx)

		end,
		TagEnd = function(self, markup, buffer, args)
			cam.PopModelMatrix()
			local xdif = buffer.x - self._bufferx
			local ydif = buffer.y - self._buffery 
			if ydif==0 then 
				buffer.x = buffer.x + xdif * (args[1] - 1)
			end
		end,
	},
}
chathud.Shortcuts = {}

chathud.x = 0.84 * 64

local DarkHUDYPos = ScrH() - (0.84 * 200) - (0.84 * 140)
chathud.y = DarkHUDYPos

chathud.W = 400

local blacklist = {
	["0"] = true,
	["1"] = true,
}
file.CreateDir("emoticon_cache")
file.CreateDir("emoticon_cache/twitch")
file.CreateDir("emoticon_cache/ffz")

function chathud.CreateFFZShortcuts(update)
chathud.FFZ = {}

for k,v in pairs(chathud.FFZChannels) do
	_G["chathud"]["FFZ"][v] = {} or _G["chathud"]["FFZ"][v]
end

local function ReadChannelInfo(filename, chan)
_G["chathud"]["FFZ"][chan] = {}
filename = string.lower(filename)
Msg("[ChatHUD]: FFZ data file found! Creating shortcuts... \n")
	if file.Exists(filename, "DATA") and not update then
		local data = file.Read(filename, "DATA")
		local d = util.JSONToTable(data)
		if not d then print(#data) return ErrorNoHalt("ChatHUD: Failed to read existing FFZ Emote cache.\n") end
		local name
		for name1, v in pairs(d) do
			--if isnumber(v) then continue end
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
				if (cont.name) and not chathud.Shortcuts[cont.name] and not blacklist[cont.name] then 
					local url
					if cont.urls[4] then url=cont.urls[4] elseif cont.urls[2] then url=cont.urls[2] else url=cont.urls[1] end
					chathud.Shortcuts[cont.display_name or cont.name] = "<ffz=" .. string.Replace( url, "//cdn.frankerfacez.com/", "" ) .. ","..tostring(cont.height*1.5 or 32)..", "..tostring(cont.width*1.5 or 32)..">" 
					table.insert(_G["chathud"]["FFZ"][chan], cont.display_name or cont.name)
				end

				end
		end
	end
end

local function DownloadChannelInfo(chan)
 	local chan = string.lower(chan)
	local filename = "emoticon_cache/ffz_global_emotes_" .. chan .. ".dat"
Msg("[ChatHUD]: FFZ data for channel "..chan.." not found! Downloading... \n")

		http.Fetch("https://api.frankerfacez.com/v1/room/"..tostring(chan), function(b)
			local d = util.JSONToTable(b)
			if not d then return ErrorNoHalt("ChatHUD: Failed to updated FFZ Emote cache.\n") end

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
				if (cont.name) and not chathud.Shortcuts[cont.name] and not blacklist[cont.name] then 
					local url
					if cont.urls[4] then url=cont.urls[4] elseif cont.urls[2] then url=cont.urls[2] else url=cont.urls[1] end
					chathud.Shortcuts[cont.display_name or cont.name] = "<ffz=" .. string.Replace( url, "//cdn.frankerfacez.com/", "" ) .. ","..tostring(cont.height*1.5 or 32)..", "..tostring(cont.width*1.5 or 32)..">" 
					table.insert(_G["chathud"]["FFZ"][chan], cont.display_name or cont.name)
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



local found = file.Find("emoticon_cache/ffz_global_emotes_*.dat", "DATA")

for k,chan in pairs(chathud.FFZChannels) do
	if table.HasValue(found,"ffz_global_emotes_"..string.lower(chan)..".dat") then 
		ReadChannelInfo("emoticon_cache/ffz_global_emotes_"..string.lower(chan)..".dat", string.lower(chan))
	else
		DownloadChannelInfo(string.lower(chan))
	end

end

end
chathud.CreateFFZShortcuts()



function chathud.CreateTwitchShortcuts(update)
	local tag = os.date("%Y%m%d")
	local latest = "twitch_global_emotes_" .. tag .. ".dat"

	local found = file.Find("emoticon_cache/twitch_global_emotes_*.dat", "DATA")
	for k, v in next,found do
		if v ~= latest then file.Delete("emoticon_cache/" .. v) end
	end

	latest = "emoticon_cache/" .. latest

	if file.Exists(latest, "DATA") and not update then
		local data = file.Read(latest, "DATA")

		local d = util.JSONToTable(data)
		if not d then return ErrorNoHalt("ChatHUD: Failed to read existing Twitch Emote cache.\n") end

		for name, v in pairs(d) do
			if not chathud.Shortcuts[name] and not blacklist[name] then chathud.Shortcuts[name] = "<te=" .. v.id .. ">" end
		end
	else
		http.Fetch("https://twitchemotes.com/api_cache/v3/global.json", function(b)
			local d = util.JSONToTable(b)
			if not d then return ErrorNoHalt("ChatHUD: Failed to updated Twitch Emote cache.\n") end

			for name, v in pairs(d) do
				if not chathud.Shortcuts[name] and not blacklist[name] then chathud.Shortcuts[name] = "<te=" .. v.id .. ">" end
			end

			file.Write(latest, b)
		end)
	end
end
chathud.CreateTwitchShortcuts()

chathud.markups = {}

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

local function CompileExpression(str)
	local env = env()

	local ch = str:match("[^=1234567890%-%+%*/%%%^%(%)%.A-z%s]")
	if ch then
		return "expression:1: invalid character " .. ch
	end

	local compiled = CompileString("return (" .. str .. ")", "expression", false)
	if isstring(compiled) then
		compiled = CompileString(str, "expression", false)
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


--[[

	PepeLaugh YOU DONT EVEN KNOWN WHAT YOU ARE GOING INTO PepeLaugh

	Wear eye protection.

]]

local tagptrn = "(.-)=(.+)"
local tagendptrn = "/(.+)"
local spacearg = "[%s]*(.-)[%s]*,"	--match arg from a tag and sanitize spaces and potential commas
local lastarg = "[%s]*(.+)[%s]*,*"	--match last arg in a tag

--[[
	Returns a string without tags + draw queue for the tags (tag -> text -> tag -> text ...)
]]

function ParseTags(str)

	local tags = {}
	
	local prevtagwhere

	for s1 in string.gmatch(str, ":(.-):") do --shortcuts, then tags 

		if chathud.Shortcuts[s1] then 
			str = str:gsub((":%s:"):format(s1), chathud.Shortcuts[s1], 1)
		end
		
	end

	for s1 in string.gmatch( str, "%b<>" ) do
		local tagcont = s1:GetBetween("<>")

		if not tagcont then return end

		local starts = str:find(s1, 1, true)

		if not prevtagwhere then 
			tags[#tags + 1] = str:sub(1, starts-utflen(str))
		end

		local tag, argsstr = tagcont:match(tagptrn)

		local chTag = chathud.Tags[tag]

		if not chTag then 
			local isend = tagcont:match(tagendptrn)
			if not isend or not chathud.Tags[isend] then print("no such tag:", tag, isend) continue end

			for k,v in ipairs(table.Reverse(tags)) do
				if not istable(v) then continue end  
				if v.tag == isend and not v.ends and not v.ender then 
					--create an ender tag, which will disable tag at k
					v.ends = starts 
					str = str:gsub(s1:PatternSafe(), "", 1)

					local key = #tags + 1

					if prevtagwhere then 
						tags[key] = str:sub(prevtagwhere, starts+utflen(str)-2)	--if ender, put text first ender later
						key = key + 1
					end

					tags[key] = {
						tag = isend, 
						ender = true, 
						ends = v.realkey,	--ends tag with key v.realkey
						realkey = key
					}
					
					prevtagwhere = starts--+1

					break
				end 
			end
			continue
		end

		local args = {}

		for argtmp in string.gmatch(argsstr, ".-,") do 
			local arg = argtmp:match(spacearg)

			argsstr = argsstr:gsub(argtmp:PatternSafe(), "", 1)

			local exp = arg:match("%[(.+)%]") 

			if exp then 

				local func = CompileExpression(exp)

				if isstring(func) then 
					print("Expression error: " .. func)
					continue
				end 

				args[#args + 1] = func 
				continue
			end

			local num = #args + 1

			if not chTag.args[num] then break end 

			local typ = chTag.args[num].type
			if not chathud.TagTypes[typ] then print("Unknown argument type! ", typ) break end 

			args[#args + 1] = chathud.TagTypes[typ](arg)
		end 

		local key = #tags + 1

		local lastarg = argsstr:match(lastarg) 
		local exp = lastarg:match("%[(.+)%]") 

		if exp then 

			local func = CompileExpression(exp)

			if isstring(func) then 
				print("Expression error: " .. func)
			end 

			args[#args + 1] = func 
			
		else
			args[#args + 1] = lastarg 
		end

		str = str:gsub(s1:PatternSafe(), "", 1)

		if prevtagwhere then 

			tags[key] = str:sub(prevtagwhere+utflen(str)-1, starts-1)
			key = key + 1

		end


		for k,v in pairs(chTag.args) do 
			if isnumber(args[k]) then
				if v.min then 
					args[k] = math.max(args[k], v.min)
				end 
				if v.max then 
					args[k] = math.min(args[k], v.max)
				end
			end

			if not args[k] then 
				args[k] = v.default 
			end 

		end

		tags[key] = {
			tag = tag, 
			args = args,
			starts = starts,
			realkey = key --for ender to keep track due to table reversing
		}

		prevtagwhere = starts
	end

	tags[#tags + 1] = string.sub(str, (prevtagwhere and prevtagwhere+utflen(str)-1) or 1, #str)


	return str, tags
end

function chathud:AddMarkup()
	
end

function chathud:CleanupOldMarkups()
	
end

local consoleColor = Color(106, 90, 205, 255)
chathud.History = {}
chathud.HistNum = 0

local names = {}

function chathud:AddText(...)

	local cont = {...}

	local time = CurTime()
	local nw = 0

	local contents = "" --actual msg

	local msgstarted = false 
	local entparsed = false 

	local name = ""	--sender name

	local retcont = {}

	local fulltxt = ""
	local wrappedtxt = "" --duh


	for k,v in ipairs(cont) do --preparse tags

		--[[ 
			Parse entity name. 
			Usually the sender, except on very rare occasions. 
		]]

		if isentity(v) then 
			fulltxt = fulltxt .. ((v.Nick and v:Nick()) or "Console")
			continue
		end

		if not isstring(v) then continue end 

		fulltxt = fulltxt .. v
	end

	local tags = {}
	--local untagged, tags, buffer = ParseTags(fulltxt)

	local curwidth = 0

	local merged = {} --final table, containing everything 

	for k,v in ipairs(cont) do 

		--[[ 
			Parse entity name and color. 
			Usually the sender, except on very rare occasions. 
		]]

		if isentity(v) then 
			local col = GAMEMODE.GetTeamColor and GAMEMODE:GetTeamColor(v)
			--cont[k] = col 
			merged[#merged + 1] = col 

			local n = (v.Nick and v:Nick()) or "Console"
			names[v], nw = string.WordWrap(n, chathud.W, "CH_Name")

			nw = nw[1]
			merged[#merged + 1] = n --table.insert(cont, k+1, n)

			name = name .. names[v]
			entparsed = true 

			continue
		end

		--[[
			Tag-parse the string and merge content table and tag table while also word-wrapping them.
		]]

		if isstring(v) then

			if msgstarted then 
				contents = contents .. v
			end

			local untagged, tags = ParseTags(v)

			surface.SetFont("CH_Text")
			

			for k2,tg in pairs(tags) do 

				if isstring(tg) then
					local tw, th = surface.GetTextSize(tg)

					local str, wds = string.WordWrap(tg, {chathud.W - curwidth, chathud.W})
					curwidth = wds[#wds] or tw
					wrappedtxt = wrappedtxt .. str
					merged[#merged + 1] = str
					continue 
				end

				if istable(tg) then 	--tag
					merged[#merged + 1] = tg
				end
			end

			if v==": " and entparsed then entparsed = false msgstarted = true end
				
		end
		if IsColor(v) then 
			merged[#merged + 1] = v 
		end
	end

	local ignore = {}

	contents = untagged
	cont.tags = tags or {}
	local key = #self.History + 1
	self.History[key] = {
		t = time,	--time(for history time tracking)
		a = 255,	--alpha(for history fadeout)
		c = merged,	--contents(text+colors to show)

		name = name,	--sender name
		namelen = utf8.len(name),

		fulltxt = fulltxt,	--just the text
		wrappedtxt = wrappedtxt,

		tags = tags,		--tags parsed
		buffer = buffer,	--buffer to use
		realkey = key,
	}

end

function chathud:Think()

end

function chathud:Invalidate(now)
	
end

function chathud:PerformLayout()
	
end

function chathud:TagPanic()
	for _, markup in pairs(self.markups) do
		markup:TagPanic(false)
	end
end

surface.CreateFont("CH_Text", {
        font = "Roboto",
        size = 22,
        weight = 400,
})

surface.CreateFont("CH_Name", {
    font = "Titillium Web SemiBold",
    size = 28,
    weight = 400,
})

surface.CreateFont("CH_NameShadow", {
    font = "Titillium Web SemiBold",
    size = 28,
    weight = 400,
    blursize = 3
})

surface.CreateFont("CH_TextShadow", {
        font = "Roboto",
        size = 22,
        weight = 400,
        blursize = 3,

})

local matrix = Matrix()

chathud.CharH = 22


local function DrawText(txt, buffer, y, x, a)
	local y = y

	local xo, yo = unpack(buffer.translate or {0, 0})

	local font = buffer.font or "CH_Text"

	local col = buffer.fgColor or Color(255, 255, 255)

	local amtoflines = 0
	local lines = {}
	local h = 22

	for s in string.gmatch(txt, "(.-)\n") do 

		surface.SetFont( font .. "Shadow")

		surface.SetTextColor( ColorAlpha(Color(0,0,0), a) )

		for i=1, 2 do
			surface.SetTextPos(buffer.x + i, buffer.y + i )
			surface.DrawText(s)
			if addText then
				surface.DrawText(addText)
			end
		end

		local tx, ty = surface.GetTextSize(s)

		surface.SetFont(font)

		surface.SetTextColor(ColorAlpha(col, a))

		surface.SetTextPos(buffer.x, buffer.y)

		surface.DrawText(s)

		buffer.y = buffer.y + ty
		buffer.x = x
		h = h + ty

		txt = txt:gsub(s:PatternSafe() .. "\n", "", 1)

	end

	surface.SetFont( font .. "Shadow")

	surface.SetTextColor( ColorAlpha(Color(0,0,0), a) )

	for i=1, 2 do
		surface.SetTextPos(buffer.x + i, buffer.y + i )
		surface.DrawText(txt)
		if addText then
			surface.DrawText(addText)
		end
	end

	local tx, ty = (surface.GetTextSize(txt))

	surface.SetFont(font)
	

	surface.SetTextColor(ColorAlpha(col, a))

	surface.SetTextPos(buffer.x, buffer.y)

	surface.DrawText(txt)

	buffer.x = buffer.x + tx

	return h
end

function chathud:Draw()
	local x, y = self.x, self.y 
	local chh = chathud.CharH 
	

	for histnum,dat in SortedPairs(self.History, true) do

		if dat.t - CurTime() < -5 or y < (self.y-220) then 
			local mult = 120

			if y < (self.y-220) then 
				mult = 500
			end

			dat.a = dat.a - FrameTime() * mult
			if dat.a <= 0 or y < 0 or (histnum < 20 and #self.History > 20) then 

				table.remove(self.History, histnum)
				return
			end
		end

		local tags = dat.tags

		local name = dat.name
		local nlen = dat.namelen

		local text = dat.text
		

		local cols = {}
		
		--[[

			DrawQueue types:

			Text: {string = true, cont = "I am the content.", san = true/false} // san means if the string should be sanitized("#VAC_ConnectionRefusedDetail")
			Tag: {tag = true, args = {}, TagStart = func, ModifyBuffer = func, TagEnd = func}
			Color: {color = true, cont = Color}

		]]

		local drawq = {}
		local tagfuncs = {}
		if not dat.DrawQ then

			--[[
				Create a Draw Queue table, which will define & parse objects and the order they will be executed in.
				This includes tags, texts, colors and entities.
			]]

			for k,v in ipairs(dat.c) do 

				--Parse color in data:

				if IsColor(v) then 
					drawq[#drawq+1] = {color = true, cont = v}
					continue
				end

				--[[
					Parse string in data.
					Handles shitty language exploits("#VAC_ConnectionRefusedDetail")
				]]

				if isstring(v) then 

					if drawq[#drawq].string then 

						drawq[#drawq].cont = drawq[#drawq].cont .. v

						if drawq[#drawq].san then 

							local sub = drawq[#drawq].cont:sub(2)

							if language.GetPhrase(sub) == sub then 
								drawq[#drawq].san = nil 
							end 

						end

					else 

						local sub = string.sub(v, 2)
						local san = false

						if v[1] == "#" and language.GetPhrase(sub) ~= sub then
							san = true
						end

						drawq[#drawq+1] = {cont = v, string = true, san = true}
					
					end

					continue
				end

				
				if istable(v) then 

					--TODO: Tag add to draw 
					local func
					local tag = {} --for storing data within the tag's function

					if v.ender then 
						func = function(buf)
							Run(tagfuncs[v.ends].TagEnd, tag, tag, buf, Run(tagfuncs[v.ends].getargs))
						end

						drawq[#drawq+1] = {name = v.tag, func = func, ender = v.ends}
					else 
						local chTag = chathud.Tags[v.tag]
						if not chTag then continue end --???

						local getargs = function()
							local args = {}

							for key, val in pairs(v.args) do 
								if isfunction(val) then 
									local ok, ret = pcall(val)
									if not ok then print("Tag error!", ret) continue end 

									

									if not ret then 
										local val = chTag.args[key].default

										if not tag.ComplainedAboutReturning then
											print("Tag function must return a value! Defaulting to", val)
											tag.ComplainedAboutReturning = true
										end

										args[key] = val

									elseif ret then

										args[key] = ret 

									end

								else 

									args[key] = val 

								end
							end 
							return args
						end

						func = function(buf)
							local args = getargs()

							Run(chTag.TagStart, buf, buf, buf, args)
							Run(chTag.Draw, buf, buf, buf, args)
							Run(chTag.ModifyBuffer, buf, buf, buf, args)
							

						end 

						drawq[#drawq+1] = {name = v.tag, func = func, TagEnd = chTag.TagEnd, ends = v.ends, getargs = getargs}
						tagfuncs[v.realkey] = {TagStart = chTag.TagStart, ModifyBuffer = chTag.ModifyBuffer, TagEnd = chTag.TagEnd}
					end
					--drawq[#drawq+1] = v
					continue
				end

				--functions are ignored

			end
			dat.DrawQ = drawq 
		end

		drawq = table.Copy(dat.DrawQ)

		local lastseg = 0
		

		local a = dat.a
		local col = Color(255,255,255)

		
		local buffer = {}

		buffer.y = y
		buffer.x = x 
		buffer.h = chh 
		buffer.w = 0
		
		local buf = buffer
		

		local amtoflines = 0

		for s in string.gmatch(dat.wrappedtxt, "(.-)\n") do 
			amtoflines = amtoflines + 1 
		end

		buffer.y = buffer.y - amtoflines*22

		for k,v in ipairs(drawq) do 

			if v.string then 
				DrawText(v.cont, buf, y, x, a)
				continue
			end

			if v.color then 
				buffer.fgColor = v.cont 
				continue
			end

			if v.func then
				buffer.fgColor = ColorAlpha(buffer.fgColor, a)
				v.func(buffer)
				print("eeeeeeee", buffer.h)
			end
		end
		print(buffer.h, "yes?")
		for k,v in ipairs(drawq) do 
			if not v.ender and not v.ends and v.func and v.TagEnd then 
				v.TagEnd(buf, buf, buffer, v.getargs and v.getargs())
			end
		end

		y = y - buffer.h

		--for k,v in pairs(tagdraw) do 
		--	if v[2] then v[2](dat, buffer, buffer) end
		--end
	end

end

-------------------------

local emoticon_cache = {}
local busy = {}

local function MakeCache(filename, emoticon)
	local mat = Material("data/" .. string.lower(filename), "noclamp smooth")
	filename=string.lower(filename)
	emoticon_cache[emoticon or string.StripExtension(string.GetFileFromFilename(filename))] = mat

end

local Mcche = {}

local function MaterialCache(a, b)
	a = a:lower()
	if Mcche[a] then return Mcche[a] end
	local m = Material(a, b)
	Mcche[a] = m
	return m
end

local dec
do
	local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	function dec(data)
		data = string.gsub(data, "[^" .. b .. "=]", "")
		return data:gsub(".", function(x)
			if x == "=" then return "" end
			local r, f = "", b:find(x) - 1
			for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end
			return r
		end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
			if #x ~= 8 then return "" end
			local c = 0
			for i = 1,8 do c = c + (x:sub(i,i) == "1" and 2 ^ (8 - i) or 0) end
			return string.char(c)
		end)
	end
end

function chathud:GetSteamEmoticon(emoticon)
	emoticon = emoticon:gsub(":",""):Trim()
	if emoticon_cache[emoticon] then
		return emoticon_cache[emoticon]
	end
	if busy[emoticon] then
		return false
	end
	if file.Exists("emoticon_cache/" .. emoticon .. ".png", "DATA") then
		MakeCache("emoticon_cache/" .. emoticon .. ".png", emoticon)
	return emoticon_cache[emoticon] or false end
	Msg"ChatHUD " print("Downloading emoticon " .. emoticon)
	http.Fetch("http://steamcommunity-a.akamaihd.net/economy/emoticonhover/:" .. emoticon .. ":	", function(body, len, headers, code)
		if code == 200 then
			if body == "" then
				Msg"ChatHUD " print("Server returned OK but empty response")
			return end
			Msg"ChatHUD " print("Download OK")
			local whole = body
			body = body:match("src=\"data:image/png;base64,(.-)\"")
			if not body then Msg"ChatHUD " print("ERROR! (no body)", whole) return end
			local b64 = body
			body = dec(body)
			if not body then Msg"ChatHUD " print("ERROR! (not b64)", b64) return end
			file.Write("emoticon_cache/" .. emoticon .. ".png", body)
			MakeCache("emoticon_cache/" .. emoticon .. ".png", emoticon)
		else
			Msg"ChatHUD " print("Download failure. Code: " .. code)
		end
	end)
	busy[emoticon] = true
	return false
end

function chathud:GetFFZEmoticon(emoticon)
	if emoticon_cache[emoticon] then
		return emoticon_cache[emoticon]
	end
	if busy[emoticon] then
		return false
	end
	if file.Exists("emoticon_cache/ffz/" .. emoticon, "DATA") then
		MakeCache("emoticon_cache/ffz/" .. emoticon, emoticon)
	return emoticon_cache[emoticon] or false end
	Msg"ChatHUD " print("Downloading FFZ emoticon https://cdn.frankerfacez.com/" .. emoticon)
	http.Fetch("https://cdn.frankerfacez.com/" .. emoticon, function(body, len, headers, code)
		if code == 200 then
			if body == "" then
				Msg"ChatHUD " print("Server returned OK but empty response")
			return end
			Msg"ChatHUD " print("Download OK")
			file.Write("emoticon_cache/ffz/" .. string.lower(emoticon) , body)
			MakeCache("emoticon_cache/ffz/" .. emoticon , emoticon)
		else
			Msg"ChatHUD " print("Download failure. Code: " .. code)
		end
	end, function() print("why emote dead wtf????") end)
	busy[emoticon] = true
	return false
end

function chathud:GetTwitchEmoticon(emoticon)
	if emoticon_cache[emoticon] then
		return emoticon_cache[emoticon]
	end
	if busy[emoticon] then
		return false
	end
	if file.Exists("emoticon_cache/twitch/" .. emoticon .. ".png", "DATA") then
		MakeCache("emoticon_cache/twitch/" .. emoticon .. ".png", emoticon)
	return emoticon_cache[emoticon] or false end
	Msg"ChatHUD " print("Downloading emoticon " .. emoticon)
	http.Fetch("https://static-cdn.jtvnw.net/emoticons/v1/" .. emoticon .. "/3.0", function(body, len, headers, code)
		if code == 200 then
			if body == "" then
				Msg"ChatHUD " print("Server returned OK but empty response")
			return end
			Msg"ChatHUD " print("Download OK")
			file.Write("emoticon_cache/twitch/" .. emoticon .. ".png", body)
			MakeCache("emoticon_cache/twitch/" .. emoticon .. ".png", emoticon)
		else
			Msg"ChatHUD " print("Download failure. Code: " .. code)
		end
	end)
	busy[emoticon] = true
	return false
end

chathud.Tags["se"] = {
	args = {
		[1] = {type = "string", default = "error"},
		[2] = {type = "number", min = 8, max = 128, default = 40},
	},
	Draw = function(self, markup, buffer, args)
		local image, size = args[1], args[2]
		image = chathud:GetSteamEmoticon(image)
		if image == false then image = MaterialCache("error") end
		surface.SetDrawColor(buffer.fgColor)
		surface.SetMaterial(image)
		surface.DrawTexturedRect(buffer.x, buffer.y - size/4, size, size)
	end,
	ModifyBuffer = function(self, markup, buffer, args)
		local size = args[2]
		buffer.h = buffer.h + size
		print("modified?")
		if buffer.x > markup.w then
			buffer.x = buffer.x + size
		end
	end,
}

chathud.Tags["ffz"] = {
	args = {
		[1] = {type = "string", default = "error"},
		[2] = {type = "number", min = 8, max = 128, default = 40},
		[3] = {type = "number", min = 8, max = 128, default = 40},
	},
	Draw = function(self, markup, buffer, args)
		local image, size, width = args[1], args[2], args[3]
		image = chathud:GetFFZEmoticon(image)
		if image == false then image = MaterialCache("error") end
		surface.SetDrawColor(buffer.fgColor)
		surface.SetMaterial(image)
		surface.DrawTexturedRect(buffer.x, buffer.y, width, size)
	end,
	ModifyBuffer = function(self, markup, buffer, args)
		local size, width = args[2], args[3]
		buffer.h, buffer.x = size, buffer.x + width
		if buffer.x > markup.w then
			buffer.x = 0
			buffer.y = buffer.y + size
			buffer.h = buffer.y + size
		end
	end,
}

chathud.Tags["te"] = {
	args = {
		[1] = {type = "string", default = "error"},
		[2] = {type = "number", min = 8, max = 128, default = 48},
	},
	Draw = function(self, markup, buffer, args)
		local image, size = args[1], args[2]
		image = chathud:GetTwitchEmoticon(image)
		if image == false then image = MaterialCache("error") end
		surface.SetDrawColor(buffer.fgColor)
		surface.SetMaterial(image)
		surface.DrawTexturedRect(buffer.x, buffer.y, size, size)
	end,
	ModifyBuffer = function(self, markup, buffer, args)
		local size = args[2]
		buffer.h, buffer.x = size, buffer.x + size
		if buffer.x > markup.w then
			buffer.x = 0
			buffer.y = buffer.y + size
			buffer.h = buffer.y + size
		end
	end,
}

-------------------------


function chathud:DoArgs(str, argfilter)
	local argtb = str:Split(",")
	if argtb[1] == "" then argtb = {} end
	local t = {}
	for i = 1, #argfilter do
		local f = argfilter[i]
		local value
		local m = argtb[i]
		if m and m:match("%[.+%]") then
			local exp = class:new("Expression", m:sub(2, -2), function(res)
				if f.type == "number" then
					return number(res, f.min, f.max, f.default)
				else
					return res or f.default or ""
				end
			end)
			local res = exp:Compile()
			if res then
				Msg"ChatHUD " print("Expression error: " .. res)
				value = f.type == "number" and number(nil, f.min, f.max, f.default) or (f.default or "")
			else
				exp.altfilter = f
				value = function()
					return exp:Run()
				end
			end
		else
			if f.type == "number" then
				value = number(m, f.min, f.max, f.default)
			else
				value = m or f.default or ""
			end
		end
		t[i] = function()
			local a, b = _f(value)
			if a == false and isstring(b) then
				Msg"ChatHUD " print("Expression error: " .. b)
				return f.type == "number" and number(nil, f.min, f.max, f.default) or (f.default or "")
			end
			return a
		end
	end
	return t
end
ChatHUDEmoticonCache = emoticon_cache
return chathud
