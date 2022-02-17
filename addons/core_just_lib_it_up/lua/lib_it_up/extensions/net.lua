LibItUp.SetIncluded()

if SERVER then util.AddNetworkString("test") end -- good for testing

function net.WriteCompressedString(s, maxsz)
	local comp = util.Compress(s)
	local complen, slen = #comp, #s
	local iscomp = complen < slen

	local min = math.min(complen, slen)

	if min == complen then
		s = comp
	end

	local bitsz = math.min(bit.GetLen(maxsz or 0xFFFF), 16)

	if min > bit.Fill(bitsz) then
		errorf("string too big: %d %scompressed vs. %d max.", min, iscomp and "" or "un", bit.Fill(bitsz))
	end

	net.WriteBool(iscomp)
	net.WriteUInt(min, bitsz)
	net.WriteData(s, min)
end

function net.ReadCompressedString(maxsz)
	local bitsz = math.min(bit.GetLen(maxsz or 0xFFFF), 16)

	local comp = net.ReadBool()
	local len = net.ReadUInt(bitsz)
	local dat = net.ReadData(len)

										-- hey no decompression bombs on my watch
	if comp then dat = util.Decompress(dat, SERVER and 2^20 or nil) end

	return dat
end

function net.WriteSteamID(what)
	local id
	if isstring(what) and what:IsSteamID() then
		id = what
	end

	if IsPlayer(what) then
		id = what:SteamID()
	end

	if not id then
		ComplainArg(1, "steamID or player", type(what))
		return
	end

	local univ, y, acc_id = id:gsub("^STEAM_", ""):match("^(%d+):(%d+):(%d+)")

	net.WriteUInt(tonumber(univ), 8)
	net.WriteBit(tonumber(y))
	net.WriteUInt(tonumber(acc_id), 31)
end

function net.ReadSteamID()
	local univ, y, acc_id

	univ = net.ReadUInt(8)
	y = net.ReadBit()
	acc_id = net.ReadUInt(31)

	return ("STEAM_%d:%d:%d"):format(univ, y, acc_id)
end


function net.WriteSteamID64(sid)
	local is_autismal = not sid:match("^76561")

	net.WriteBool(is_autismal)

	if is_autismal then
		net.WriteString(sid)
	else
		net.WriteDouble(sid:match("76561(%d+)"))
	end
end

function net.ReadSteamID64()
	local is_shit = net.ReadBool()
	local ret

	if is_shit then
		ret = net.ReadString()
	else
		ret = "76561" .. net.ReadDouble()
	end

	return ret
end
