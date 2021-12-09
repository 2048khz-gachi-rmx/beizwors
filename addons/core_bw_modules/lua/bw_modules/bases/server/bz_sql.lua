--

local bw = BaseWars.Bases

local zones_tbl = "bw_baseareas"
local bases_tbl = "bw_bases"

local function PopulateBases(bases)
	for baseID, data in pairs(bases) do
		local base = bw.Base:new(baseID, data.json)
			:SetName(data.name)

		for _, zonedata in ipairs(data.zones) do
			local zoneID, zoneName, mins, maxs = unpack(zonedata)
			local zone = bw.Zone:new(zoneID, mins, maxs)
			if zoneName then
				zone:SetName(zoneName)
			end
			base:AddZone(zone)
			zone:AddToNW()
		end

		base:AddToNW()

	end

	bw.Log("SQL data pulled!")
	hook.NHRun("BWBasesLoaded")
end

local sides = {"min", "max"}
local dims = {"x", "y", "z"}

local argnames = {min = {}, max = {}}
local allArgNames = {}

for k,v in ipairs(sides) do
	for _, v2 in ipairs(dims) do
		local argname = "zone_" .. v .. "_" .. v2
		argnames[v][v2] = argname
		allArgNames[#allArgNames + 1] = argname
	end
end

function bw.SQLResync()
	mysqloo.OnConnect(coroutine.wrap(function()
		local db = mysqloo:GetDatabase()

		-- creating bases table

		local basesArg = LibItUp.SQLArgList()
			basesArg:AddArg("base_id", "INT NOT NULL PRIMARY KEY AUTO_INCREMENT")
			basesArg:AddArg("base_name", "VARCHAR(500) NOT NULL")
			basesArg:AddArg("base_data", "JSON")
			basesArg:AddArg("map_name", "VARCHAR(128)")

		local additional = {
			"ADD UNIQUE INDEX `base_name_UNIQUE`(`base_name` ASC, `map_name` ASC)",
		}

		local cor = coroutine.Resumer()

		mysqloo.CreateTable(db, bases_tbl, basesArg, unpack(additional))
			:Then(cor)


		local zonesArg = LibItUp.SQLArgList()

		zonesArg:AddArg("zone_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT")
		zonesArg:AddArg("zone_name VARCHAR(121) NOT NULL") -- you really don't need the name to be any longer than this
		zonesArg:AddArg("base_id INT NOT NULL")	-- not PK: there can be multiple zones tied to the same base

		for k,v in ipairs(allArgNames) do
			zonesArg:AddArg(v .. " FLOAT NOT NULL")
		end

		local em = mysqloo.CreateTable(db, zones_tbl, zonesArg)
		em:Then(cor)

		local a, b = coroutine.yield();
		local c, d = coroutine.yield()	-- 2 queries, 2 yields

		local selWhat = "a.zone_id, a.zone_name, b.base_id, b.base_name, b.base_data"

		for k,v in pairs(argnames) do
			for _, v2 in pairs(v) do
				selWhat = "a." .. v2 .. ", " .. selWhat
			end
		end

		local q = ([[SELECT %s FROM `%s` a RIGHT JOIN %s b
			ON a.base_id = b.base_id
			WHERE b.map_name = "%s";]])
					:format(selWhat, zones_tbl, bases_tbl, db:escape(game.GetMap()))

		MySQLEmitter(db:query(q), true)
			:Then(function(self, q, data)
				local bases = {}	-- [base_ID] = { name = string, zones = {...} }

				for _, row in ipairs(data) do
					-- read the base ID/name (guaranteed to be present)

					local bID = row.base_id
					local json = row.base_data
					local base = bases[bID] or {
						name = row.base_name,
						json = json,
						zones = {}	-- [seq_id] = {zone_id, zone_name, zone_mins, zone_maxs}
					}

					bases[bID] = base

					-- read the zones data (not guaranteed)
					local zID = row.zone_id
					if not zID then continue end

					local mins, maxs = Vector(), Vector()
					for k,v in pairs(argnames.min) do
						mins[k] = row[v]
					end

					for k,v in pairs(argnames.max) do
						maxs[k] = row[v]
					end

					base.zones[#base.zones + 1] = {zID, row.zone_name or false, mins, maxs}
				end

				PopulateBases(bases)

				FInc.AddState("BW_SQLAreasFetched")

			end, mysqloo.CatchError)

	end))
end

--[[
	SQL operations
]]

local base_q

mysqloo.OnConnect(function()
	local qry = "INSERT INTO `bw_bases` (`base_name`, `map_name`) VALUES(?, %q)"
	qry = qry:format( mysqloo:GetDatabase():escape(game.GetMap()))
	base_q = mysqloo:GetDatabase():prepare(qry)
end)

function bw.SQL.CreateBase(name)
	local em = MySQLEmitter(base_q)

	if #name > bw.MaxBaseNameLength then
		return em, ("name is too long (%d, max is %d)"):format(#name, bw.MaxBaseNameLength)
	end

	if #name < bw.MinBaseNameLength then
		return em, ("name is too short (%d, min is %d)"):format(#name, bw.MinBaseNameLength)
	end

	if bw.GetBase(name) then
		return em, ("base `%s` already exists"):format(name)
	end

	base_q:setString(1, name)

	em:On("Success", function(qobj)
		local id = base_q:lastInsert()
		local base = bw.Base:new(id)
		base:SetName(name)
		base:AddToNW()
	end)

	return em:Exec()
end

local zone_q

mysqloo.OnConnect(function()
	local fuck = "INSERT INTO `bw_baseareas` (%s, zone_name, base_id) VALUES(%s)"
	fuck = fuck:format(table.concat(allArgNames, ", "), ("?, "):rep(#allArgNames + 2):sub(1, -3))

	zone_q = mysqloo:GetDatabase():prepare(fuck)
end)


function bw.SQL.CreateZone(name, baseid, min, max)
	local em = MySQLEmitter(zone_q)

	if #name > bw.MaxZoneNameLength then
		return em, ("name is too long (%d, max is %d)"):format(#name, bw.MaxZoneNameLength)
	end

	if not bw.GetBase(baseid) then
		return em, ("no base found for %s"):format(baseid)
	end
	local base = bw.GetBase(baseid)


	for i=1, 3 do
		zone_q:setNumber(i, min[i])
	end

	for i=4, 6 do
		zone_q:setNumber(i, max[i-3])
	end

	zone_q:setString(7, name)
	zone_q:setNumber(8, baseid)

	em:On("Success", function(qobj)
		local id = zone_q:lastInsert()
		local zone = bw.Zone:new(id, min, max)
		zone:SetName(name)
		zone:AddToNW()
		base:AddZone(zone)
	end)

	return em:Exec()
end

local edit_zone_q
local edit_base_q
local data_base_q

mysqloo.OnConnect(function()
	local fuck = "UPDATE `bw_baseareas` SET %s, zone_name = ? WHERE (`zone_id` = ?);"
	fuck = fuck:format(
		-- SET `name` = ?, `name` = ?
		table.concat(allArgNames, " = ?, ") .. " = ?"
	)
	-- UPDATE bw_baseareas SET zone_name = ?, zone_min_x = ?, zone_min_y = ?, zone_min_z = ?, zone_max_x = ?, zone_max_y = ?, zone_max_z = ? WHERE (`zone_id` = ?);
	edit_zone_q = mysqloo:GetDatabase():prepare(fuck)

	local fuck = "UPDATE `%s` SET base_name = ? WHERE (`base_id` = ?);"
	fuck = fuck:format(bases_tbl)

	edit_base_q = mysqloo:GetDatabase():prepare(fuck)

	local fuck = "UPDATE `%s` SET base_data = ? WHERE (`base_id` = ?);"
	fuck = fuck:format(bases_tbl)
	data_base_q = mysqloo:GetDatabase():prepare(fuck)
end)


function bw.SQL.EditZone(id, name, min, max)
	local em = MySQLEmitter(edit_zone_q)

	if #name > bw.MaxZoneNameLength then
		return em, ("name is too long (%d, max is %d)"):format(#name, bw.MaxZoneNameLength)
	end

	local zone = bw.GetZone(id)
	if not zone then
		return em, ("no zone found with id %s"):format(id)
	end

	for i=1, 3 do
		edit_zone_q:setNumber(i, min[i])
	end

	for i=4, 6 do
		edit_zone_q:setNumber(i, max[i-3])
	end

	edit_zone_q:setString(7, name)
	edit_zone_q:setNumber(8, id)

	em:On("Success", function(qobj)
		zone:SetName(name)
		zone:SetBounds(min, max)
		zone:AddToNW()
	end)

	return em:Exec()
end

function bw.SQL.EditBase(id, name)
	local em = MySQLEmitter(edit_base_q)

	if #name > bw.MaxBaseNameLength then
		return em, ("name is too long (%d, max is %d)"):format(#name, bw.MaxZoneNameLength)
	end

	local base = bw.GetBase(id)
	if not base then
		return em, ("no base found with id %s"):format(id)
	end

	edit_base_q:setString(1, name)
	edit_base_q:setNumber(2, id)

	em:On("Success", function(qobj)
		base:SetName(name)
		base:AddToNW()
	end)

	return em:Exec()
end

function bw.SQL.SaveData(id, json)
	local em = MySQLEmitter(data_base_q)

	local base = bw.GetBase(id)
	if not base then
		return em, ("no base found with id %s"):format(id)
	end

	data_base_q:setString(1, json)
	data_base_q:setNumber(2, id)

	return em:Exec()
end

local yeet_zone_q
local yeet_base_q

mysqloo.OnConnect(function()
	local yeetzone = "DELETE FROM `%s` WHERE (`zone_id` = ?);"
	yeetzone = yeetzone:format(zones_tbl)

	local yeetbase = "DELETE FROM `%s` WHERE (`base_id` = ?);"
	yeetbase = yeetbase:format(bases_tbl)

	yeet_zone_q = mysqloo:GetDatabase():prepare(yeetzone)
	yeet_base_q = mysqloo:GetDatabase():prepare(yeetbase)
end)

function bw.SQL.YeetZone(id)
	local em = MySQLEmitter(yeet_zone_q)

	local zone = bw.GetZone(id)
	if not zone then
		return em, ("no zone found with id %s"):format(id)
	end

	yeet_zone_q:setNumber(1, id)

	em:On("Success", function(qobj)
		zone:Remove()
	end)

	return em:Exec()
end

function bw.SQL.YeetBase(id)
	local em = MySQLEmitter(yeet_base_q)

	local base = bw.GetBase(id)
	if not base then
		return em, ("no base found with id %s"):format(id)
	end

	yeet_base_q:setNumber(1, id)

	em:On("Success", function(qobj)
		base:Remove()
	end)

	return em:Exec()
end