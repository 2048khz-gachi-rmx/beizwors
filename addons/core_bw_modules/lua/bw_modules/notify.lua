MODULE.Name 	= "Notify"
MODULE.Author 	= "Q2F2 & Ghosty"

BaseWars.Notify = {}
local MODULE = BaseWars.Notify


if SERVER then
	util.AddNetworkString("BWNotify")
end

NOTIFY_CONSOLE = 0
NOTIFY_CHAT = 1
NOTIFY_POPUP = 2

local actions = {
	[NOTIFY_CONSOLE] = function(_, ...)
		MsgC(color_white, ...)
		MsgC("\n")
	end,

	[NOTIFY_CHAT] = function(_, ...)
		chat.AddText(...)
	end,

	[NOTIFY_POPUP] = function(typ, str, dur, ...)
		notification.AddTimed(str, typ, dur or 5)
		MsgC(str)
	end
}

function MODULE._WriteLang(lang, ...)
	lang:Write()

	net.WriteUInt(select("#", ...), 8)
	for k,v in ipairs({...}) do
		Networkable.WriteEncoder(v)
	end
end

function MODULE._ReadLang()
	local fmt = net.ReadLocalString()
	local argSz = net.ReadUInt(8)
	local args = {}

	for i=1, argSz do
		args[i] = Networkable.ReadByDecoder()
	end

	return fmt, args
end

function MODULE._Add(not_typ, arg, str, ...)
	if not CLIENT then
		net.Start("BWNotify")
			net.WriteUInt(not_typ, 4)
			if not_typ == NOTIFY_POPUP then net.WriteUInt(arg, 4) end

			if IsLocalString(str) then
				net.WriteUInt(0, 4)
				MODULE._WriteLang(str, ...)

			elseif isstring(str) then
				net.WriteUInt(1, 4)
				net.WriteCompressedString(str)

			elseif istable(str) then
				net.WriteUInt(2, 4)
				net.WriteUInt(#str, 8)
				for k,v in ipairs(str) do
					if IsLocalString(v) then
						net.WriteBool(true)
						MODULE._WriteLang(v, unpack(str, k + 1))
						break
					end

					net.WriteBool(false)
					Networkable.WriteEncoder(v)
				end
			end

		-- sending is up to you
		return
	end

	actions[not_typ] (arg, str, ...)
end

function MODULE.LogNotify(str, ...)
	MODULE._Add(NOTIFY_CONSOLE, nil, str, ...)
end

function MODULE.ChatNotify(...)
	MODULE._Add(NOTIFY_CHAT, nil, ...)
end

function MODULE.PopupNotify(typ, str, ...)
	assert(isnumber(typ), "1st arg should be notif type")
	MODULE._Add(NOTIFY_POPUP, typ, str, ...)
end

if CLIENT then
	net.Receive("BWNotify", function(len)
		local notif_typ = net.ReadUInt(4)

		local popup_typ
		if notif_typ == NOTIFY_POPUP then popup_typ = net.ReadUInt(4) end

		local data_typ = net.ReadUInt(4)

		if data_typ == 0 then
			-- received local string
			local fmt, args = MODULE._ReadLang()

			MODULE._Add(notif_typ, popup_typ, fmt(unpack(args)))

		elseif data_typ == 1 then
			-- received string
			local str = net.ReadCompressedString()
			if str and str:sub(1, 2) ~= "\\#" then
				str = language.GetPhrase(str)
			end

			MODULE._Add(notif_typ, popup_typ, str)

		elseif data_typ == 2 then
			-- received table
			local argSz = net.ReadUInt(8)
			local args = {}

			for i=1, argSz do
				local is_lang = net.ReadBool()
				if is_lang then
					local lang, langargs = MODULE._ReadLang()
					args[i] = lang(unpack(langargs))
					break
				end

				args[i] = Networkable.ReadByDecoder()
				if isstring(args[i]) and args[i]:sub(1, 2) ~= "\\#" then
					args[i] = language.GetPhrase(args[i])
				end
			end

			MODULE._Add(notif_typ, popup_typ, unpack(args))
		end
	end)
end