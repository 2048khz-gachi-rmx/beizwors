aowl.AddCommand("kick", function(ply, line, target, reason)
	local ent = easylua.FindEntity(target)

	if ent:IsPlayer() then

		local rsn = reason or "see you later"

		aowlMsg("kick", tostring(ply).. " kicked " .. tostring(ent) .. " for " .. rsn)
		hook.Run("AowlTargetCommand", ply, "kick", ent, rsn)

		return ent:Kick(rsn or "see you later")

	end

	return false, aowl.TargetNotFound(target)
end, "mods")

local ok={d=true,m=true,y=true,s=true,h=true,w=true}
local function parselength_en(line) -- no months. There has to be a ready made version of this.

	local res={}

	line=line:Trim():lower()
	if tonumber(line)~=nil then
		res.m=tonumber(line)
	elseif #line>1 then
		line=line:gsub("%s","")
		for dat,what in line:gmatch'([%d]+)(.)' do

			if res[what] then return false,"bad format" end
			if not ok[what] then return false,("bad type: "..what) end
			res[what]=tonumber(dat) or -1

		end
	else
		return false,"empty string"
	end

	local len = 0
	local d=res
	local ok
	if d.y then	ok=true len = len + d.y*31556926 end
	if d.w then ok=true len = len + d.w*604800 end
	if d.d then	ok=true len = len + d.d*86400 end
	if d.h then	ok=true len = len + d.h*3600 end
	if d.m then	ok=true len = len + d.m*60 end
	if d.s then	ok=true len = len + d.s*1 end

	if not ok then return false,"nothing specified" end
	return len

end

aowl.AddCommand("ban", function(ply, line, target, length, reason)
	local id = easylua.FindEntity(target)
	local ip

	if not length then length = 1440*3 end

	-- if length==0 then return false,"invalid ban length" end
	length = tonumber(length) or 1440*3

	local reason = ("You have been banned for %s.\n\n" ..
		"Welcome to the ban bubble. Duration of your stay: %s.")

		:format(
			reason or "being fucking annoying",
			(length == 0 and "two eternities") or string.NiceTime(length * 60)
		)

	if not id:IsPlayer() then return end

	ULib.ban(id, length, reason, ply)

end, "admins")