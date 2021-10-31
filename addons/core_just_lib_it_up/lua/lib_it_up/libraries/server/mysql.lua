if LibItUp then LibItUp.SetIncluded() end
require("mysqloo")

local is_dedi = jit.os == "Linux"
local liveDBInfo = {"51.178.211.29", "u34696_8lGPVh7Gv6", "8Q7geFIU3eYrOe2C", "s34696_main"}

if is_dedi then
	__MYSQL_INFO = liveDBInfo
else
	__MYSQL_INFO = {"127.0.0.1", "root", "31415", "master"}
end

mysql = mysqloo
mysqloo.Info = __MYSQL_INFO
mysqloo.__OnConnectCallbacks = {}
mysqloo.__masterSchemaExists = mysqloo.__masterSchemaExists or false

--[[if mysqloo.GlobalDatabase and mysqloo.GlobalDatabase:status() == 0 then
	mysqloo.GlobalDatabase:disconnect() --bye bye monkey
end]]


local err = Logger("MySQL ERROR", Color(230, 120, 120))

local rsDB


local function connect(ply)
	if ply and IsPlayer(ply) and not ply:IsSuperAdmin() then return false end
	if rsDB and rsDB:status() == 0 then rsDB:disconnect() end

	rsDB = mysqloo.connect(unpack(__MYSQL_INFO))

	local function completeLoad(db)
		mysqloo.__masterSchemaExists = true
		hook.Run("OnMySQLReady", db)

		if mysqloo.__OnConnectCallbacks then
			for k,v in ipairs(mysqloo.__OnConnectCallbacks) do
				v[1](unpack(v, 2))
			end
			mysqloo.__OnConnectCallbacks = nil
		end
	end

	rsDB.onConnected = function(self)
		--[[if is_dedi then
			local q = self:query("CREATE DATABASE IF NOT EXISTS master; USE master")

			q.onSuccess = function()
				completeLoad(self)
			end

			q.onError = function(self, ...)
				err("Master MySQL database creation failed.")
				err("Do `mysql_reconnect` if you want to try again.")
				err(...)
			end

			q:start()
		else]]
			completeLoad(self)
		--end
	end

	rsDB.onConnectionFailed = function(self, ...)
		err("Master MySQL database connection failed.")
		err("Do `mysql_reconnect` if you want to try again.")
		err(...)
	end

	rsDB:connect()
	mysqloo.GlobalDatabase = rsDB
end

concommand.Add("mysql_reconnect", connect)

if not mysqloo.GlobalDatabase then
	connect()
end

function mysqloo.GetDB()
	return mysqloo.GlobalDatabase
end

-- use as q.onError = mysqloo.QueryError
function mysqloo.QueryError(q, errstr, qstr)
	err("Query error!\n	\"%s\"\n\n	Query: \"%s\"\n	Trace: %s",
						errstr, 			qstr, 			debug.traceback())
end

mysqloo.HookName = "OnMySQLReady"

mysqloo.GetDatabase = mysqloo.GetDB
mysqloo.GetDataBase = mysqloo.GetDB


function mysqloo.CreateTable(db, name, ...)

	if isstring(db) then 	--database is optional; it'll just use default
		name = db
		db = mysqloo.GlobalDatabase
	end

	if db == nil then
		if mysqloo.GlobalDatabase then -- db == nil due to user error
			errorf( "mysqloo.CreateTable: no database supplied (%s, %s; %s)",
				db, name, table.concat({...}, ", ") )
			return
		else	-- db == nil due to global database not being initialized yet
			err("Attempted to create table `%s` before global database init. Attempting to recover...", name)
			mysqloo.OnConnect(mysqloo.CreateTable, name, ...)
			return false
		end
	end

	local q = "CREATE TABLE IF NOT EXISTS `%s` (%s)"
	local args = {...}

	local qargs = ""

	if args[1] then
		if not IsArgList(args[1]) then
			for k, v in ipairs(args) do
				qargs = qargs .. v
				if next(args, k) then qargs = qargs .. "," end
			end
		else
			qargs = tostring(args[1])
		end
	end

	q = q:format(name, qargs)

	local em = MySQLEmitter(db:query(q), true)
		:Catch(mysqloo.QueryError)

	return em
end

function mysqloo.OnConnect(cb, ...)
	if mysqloo.GlobalDatabase and mysqloo.GlobalDatabase:status() == 0 and mysqloo.__masterSchemaExists then
		cb(...)
	else
		table.insert(mysqloo.__OnConnectCallbacks, {cb, ...})
	end
end

local liveDB
local onLiveConnect = {}

function mysqloo.UseLiveDB()
	local pr = Promise()

	if is_dedi then
		mysqloo.OnConnect(function()
			pr:Resolve(mysqloo.GlobalDatabase)
		end)

		return pr
	end

	if mysqloo.LiveDatabase then
		if mysqloo.__liveConnected then
			pr:Resolve(mysqloo.LiveDatabase)
		else
			onLiveConnect[#onLiveConnect + 1] = pr
		end

		return pr
	end

	liveDB = mysqloo.connect(unpack(liveDBInfo))

	local function completeLoad(db)
		mysqloo.__liveConnected = true
		hook.Run("OnLiveMySQLReady", db)

		for k,v in ipairs(onLiveConnect) do
			v:Resolve(db)
		end
	end

	liveDB.onConnected = completeLoad

	liveDB.onConnectionFailed = function(self, ...)
		err("Live MySQL database connection failed.")
		err("Do `live_mysql_reconnect` if you want to try again.")
		err(...)
	end


	onLiveConnect[#onLiveConnect + 1] = pr

	liveDB:connect()
	mysqloo.LiveDatabase = liveDB

	return pr
end

function mysql.quote(db, str)
	return "'" .. db:escape(str) .. "'"
end