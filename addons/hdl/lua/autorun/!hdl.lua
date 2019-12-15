AddCSLuaFile()

hdl = hdl or {}

file.CreateDir("hdl")

sql.Query("CREATE TABLE IF NOT EXISTS hdl_Data(name TEXT UNIQUE, url TEXT)")


local BlankFunc = function() end

local queued = {}
hdl.queued = queued 

local downloading = {}
hdl.downloading = downloading 
local function Download(url, name, func, fail)
	local timed_out = false 

	http.Fetch(url, function(body)
		if timed_out then return end 
		
		file.Write(name, body)

		downloading[name] = nil 

		func("data/" .. name, body)

		local q = [[INSERT INTO hdl_Data(name, url) VALUES('%s', '%s')
  		ON CONFLICT(name) DO UPDATE SET url=excluded.url;]]
		q = q:format(SQLStr(name, true), SQLStr(url, true))
		local ok = sql.Query(q)
		if ok == false then ErrorNoHalt("Failed HDL query! ", q) end
	end, 
	function(a) 
		if timed_out then return end 

		if fail then 
			fail(a)
		else 
			print("Failed to download!\n 	", a) 
		end
		downloading[name] = nil 
	end)

	timer.Simple(10, function()
		if downloading[name] then  
			downloading[name] = nil 
			if fail then 
				fail("Timed out")
			else 
				print("Failed to download!\n 	Timed out") 
			end
		end
		timed_out = true

	end)

end

local exts = {
	["txt"] = true,
	["jpg"] = true,
	["png"] = true,
	["dat"] = true,
	["json"] = true,
	["vtf"] = true,
}

function hdl.DownloadFile(url, name, func, fail, ovwrite)
	if not url then return end 
	func = func or BlankFunc 
	fail = fail or BlankFunc

	--[[

		Scanning for folders & finding them

	]]

	if name[1] ~= "-" then
		name = "hdl/" .. name
	else 
		name = name:sub(2)
	end
	
	local tbl = string.Split(name,"/")



	for k,v in pairs(tbl) do

		if v~="hdl" and v~=name then 

			if not v:find("%.") and not file.IsDir("hdl/"..v, "DATA") then 
				file.CreateDir("hdl/"..v)
			end

		end

	end

	--[[
		Checking for extension
	]]

	local filename, ext = name:match("(.+)%.(.+)")

	if not ext then 
		MsgC(Color(220, 220, 50), "[HDL] ", color_white, ("File name (%s) does not have an extension; appending .dat\n"):format(name))
	elseif not exts[ext] then 
		MsgC(Color(220, 220, 50), "[HDL] ", color_white, ("Extension (%s) in file name (%s) is not whitelisted; replacing it with .dat\n"):format(ext, name))
		name = filename .. ".dat"
	end

	local size = file.Size(name, "DATA")

	if size~=-1 and file.Size(name, "DATA")~=0 and not ovwrite then 

		local url2 = sql.Query("SELECT url FROM hdl_Data WHERE name == " .. SQLStr(name))

		if istable(url2) then 
			url2 = url2[1] 
			if url~=url2 then Download(url, name, func, fail) return end
		end 

		func("data/" .. name, file.Read("data/" .. name, "DATA"))
	return end 

	if not name then 

		local n = "hdl_unnamed"

		local fs, flds = file.Find("hdl/hdl_unnamed*", "DATA")
		local max = 1

		for k,v in pairs(fs) do 
			if v and #v and v[#v-1] > max then max = v[#v-1] end
		end
		
		name = n .. max .. ".txt"

	end 	
	local t = {url = url, name = name, func = func, fail = fail}
	local key = #queued + 1

	queued[key] = t

	timer.Simple(10, function()
		for k,v in pairs(queued) do 
			if v == t then 
				table.remove(queued, k)
				break
			end 
		end
	end)

end

httpReady = httpReady or false 

hook.Add("Think", "HDL", function()
	if not httpReady then return end 

	for k,v in pairs(queued) do 
		if downloading[v.name] then continue end 

		--if table.Count(downloading) >= 3 then break end --do not allow more than 3 downloads at a time

		downloading[v.name] = true
		Download(v.url, v.name, v.func, v.fail)
		table.remove(queued, k)
	end

end)

hook.Add("InitPostEntity", "HDL_Ready", function()
	timer.Simple(5, function() httpReady = true end)
end)

function hdl.PlayURL(url, name, flags, func, fail, ovwrite)

	hdl.DownloadFile(url, name, function(n) 
		sound.PlayFile(n, flags or "", func or BlankFunc)

	end, function(err, str)
		error("Failed HDL PlayURL! Error: " .. err .. " " .. str)

	end)
	
end

workshop = {}

function workshop.Download(id)

	steamworks.FileInfo(id, function( out )
		steamworks.Download(out.fileid, true, function(path)
			game.MountGMA(path)
		end)
	end)

end
--[[
well it's been about 5 months i think

reworked inventory networking
added a whole bunch of rendering shtuff to panels
added outfitter
rewrote dash
added research
rewrote printers
added printer rack
added printer overclocker
todo whcih uses sqlite for storing shit
equipment which uses mysql
discord relay back&forth using bromsocket
partizones structured
unimenu dumped
HeX's lib added & improved with various table objects(CommunistTable, ProxyTable, etc.)
chathud with animated emote support added
mySQL one connection for everything plus hook calling
and more...

(in progress; not functional) rewriting power system: generators & power poles
CUM: a WIP admin mod for personal use
inventory needs actual content]]