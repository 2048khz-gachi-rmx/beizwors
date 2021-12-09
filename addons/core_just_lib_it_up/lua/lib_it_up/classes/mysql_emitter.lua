LibItUp.SetIncluded()
if CLIENT then error("This isn't supposed to be included clientside.") return end --not for you, pumpkin

if not Emitter then include("emitter.lua") end

local verygood = Color(50, 150, 250)
local verybad = Color(240, 70, 70)

local function defaultCatch(q, err, sql)
	local str = "	Error: %s\n	Query: %s"
	MsgC(verygood, "[MySQLQuery ", verybad, "ERROR!", verygood, "]\n", color_white, str:format(err, sql), "\n")
end

local function defaultSuccess(q, dat)
	local str = "	Success! Returned %d rows;\n"
	MsgC(verygood, "[MySQLQuery]\n", color_white, str:format(#dat), "\n")
	PrintTable(dat or {}, 1)
end

MySQLQuery = MySQLQuery or Promise:Callable()
MySQLEmitter = MySQLQuery -- backwards compat

MySQLQuery.IsMySQLEmitter = true
MySQLQuery.IsMySQLQuery = true

function MySQLQuery:__tostring()
	return ("MySQLQuery: %p"):format(self)
end

local function doErr(who, typ, query)
	errorf("%s: expected a %s, got %s instead", who, typ, type(query))
end

local function emErr(q)
	return doErr("MySQLQuery", "MySQL query", q)
end

function MySQLQuery:Initialize(query, also_do)
	local meta = getmetatable(query)

	if not meta then emErr(query) return end
	if not meta.MetaName then emErr(query) return end

	local is_new_qry = meta.MetaName:find("MySQLOO") and meta.MetaName:find("[Qq]uery")
	local is_old_qry = meta.MetaName:find("MySQLOO table")
	local is_qry_like = query.start

	if not is_new_qry and not is_old_qry and not is_qry_like then
		emErr(query)
		return
	end

	self.Success = {}
	self.Error = {}
	self.CurrentStep = 1

	self.CatchFunc = nil

	self.reuseSucc = function(...) self:onSuccess(...) end
	self.reuseErr = function(...) self:onError(...) end

	self:Queue(query)

	if also_do then self:Exec() end
end

function MySQLQuery:onSuccess(qobj, data)
	self.CurrentQuery = nil
	self._Data = data

	self:Emit("Success", qobj, data, self.CurrentStep)
	self:Resolve(qobj, data)
end

function MySQLQuery:onError(qobj, err, query)
	local db = qobj:GetDB()


	if err == "Lost connection to server during query" or err:match("^Can't connect to server") then -- !?
		print ("!! Lost connection to DB during query !!")
		printf("!! Query: %s !!", query)
		printf("!! Error: %s !!", err)
		print ("!! Restarting... !!")

		self:Exec() -- you should restart the query... NOW!
		return
	end


	self.CurrentQuery = nil

	self:Emit("Error", qobj, err, query, self.CurrentStep)
	self:Reject(qobj, err, query)
end

function MySQLQuery:Catch(fn)
	self:Then(nil, fn) -- bruh
	return self
end

function MySQLQuery:GetData()
	return self._Data
end

function MySQLQuery:Debug()
	self:Then(function(_, ...)
		defaultSuccess(...)
	end, function(...)
		defaultCatch(...)
	end)

	return self
end

function MySQLQuery:Queue(q)
	q.onSuccess = self.reuseSucc
	q.onError = self.reuseErr

	self.CurrentQuery = q
	return self
end

function MySQLQuery:Exec()
	self._Data = nil
	self.CurrentQuery:start()
	return self
end

function MySQLQuery:Do(q)
	return self:Queue(q):Exec()
end

MySQLDatabase = MySQLDatabase or Promise:Callable()
MySQLDatabase.IsMySQLDatabase = true

local function dbErr(q)
	return doErr("MySQLDatabase", "MySQL database", q)
end

function MySQLDatabase:Initialize(db)
	local meta = getmetatable(db)

	if not meta then dbErr(db) return end

	local is_new = meta.MetaName:find("MySQLOO") and meta.MetaName:find("[Dd]atabase")
	local is_old = meta.MetaName:find("MySQLOO table")
	local is_like = db.connect

	if not is_new and not is_old and not is_like then
		dbErr(db)
		return
	end

	self.Handle = db

	if db:status() == mysqloo.DATABASE_CONNECTED then
		self:Resolve(db)
	else
		db._oldOnConnected = db.onConnected
		db.onConnected = MySQLDatabase.onConnect
		db._wrapper = self
	end
end

function MySQLDatabase.onConnect(db)
	if db._oldOnConnected then
		db:_oldOnConnected()
	end

	db._wrapper:Resolve(db)
end

function MySQLDatabase.onConnectionFailed(db, err)
	if db._oldOnConnectionFailed then
		db:_oldOnConnectionFailed(err)
	end

	db._wrapper:Reject(db, err)
end

function MySQLDatabase:GetHandle()
	return self.Handle
end

function MySQLDatabase:Query(q)
	local qry = self:GetHandle():query(q)
	return MySQLQuery(qry)
end
MySQLDatabase.query = MySQLDatabase.Query

function MySQLDatabase:Prepare(q)
	local qry = self:GetHandle():prepare(q)
	return qry
end
MySQLDatabase.prepare = MySQLDatabase.Prepare

function IsMySQLEmitter(t)
	return t.IsMySQLEmitter
end

function IsMySQLDatabase(t)
	return t.IsMySQLDatabase
end
