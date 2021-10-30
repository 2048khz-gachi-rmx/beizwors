--[[
	Report funcs:
		{1}, {2}, {3} will forward 1, 2 or 3rd argument.
		1st argument is usually the caller.
		Player colors will be automatically modified with team color
]]
local function IsPlayer(arg)
	return type(arg) == "Player"
end
CUM = CUM or {}
CUM.Receipts = CUM.Receipts or {}
CUM.Cats = {}

local log = CUM.Log

function CUM.UpdateRanks()
	local adms = {}
	for k,v in pairs(player.GetAll()) do
		if v:IsAdmin() or v:IsSuperAdmin() then
			adms[#adms + 1] = v
		end
	end
	CUM.Receipts["admins"] = adms

	local sadms = {}
	for k,v in pairs(player.GetAll()) do
		if v:IsSuperAdmin() then
			sadms[#sadms + 1] = v
		end
	end

	CUM.Receipts["superadmins"] = sadms
	CUM.Receipts["console"] = {}

	CUM.Receipts["all"] = player.GetAll()
end

CUM.UpdateRanks()

timer.Create("CUM.UpdateRanks", 10, 0, CUM.UpdateRanks)

CUM.cmds = CUM.cmds or {}

cmdfuncs = {}

local cmdmeta = {}
cmdmeta.__index = cmdfuncs

function CUM.ParsePlayer(str)
	str = str:lower()
	for _, ply in pairs(player.GetBots()) do 	--search bots first

		if ply:Nick():lower():find(str, nil, true) and IsValid(ply) then
			return ply
		end

	end

	for _, ply in pairs(player.GetHumans()) do 	--then players for start of name exact

		if ply:Nick():lower():find(str, nil, true) == 1 and IsValid(ply) then
			return ply
		end

	end

	local matches = {}

	for _, ply in pairs(player.GetHumans()) do 	--then best match

		local st, en = ply:Nick():lower():find(str, nil, true)

		if st and IsValid(ply) then
			matches[#matches+1] = {len = en-st, ply = ply}
		end

	end

	table.sort(matches, function(a, b) return a.len > b.len end)

	if matches[1] and IsValid(matches[1].ply) then return matches[1].ply else return false end
end

local boolaliases = {
	["1"] = true,
	["true"] = true,
	["y"] = true,
	["yes"] = true,
	["ys"] = true,
	["u"] = true,
	["t"] = true,

	["0"] = false,
	["false"] = false,
	["n"] = false,
	["no"] = false,
	["m"] = false,
	["b"] = false
}
function CUM.ParseBool(str)
	if not str then return -1 end

	if boolaliases[str:lower()] ~= nil then
		return boolaliases[str:lower()]
	end
end

function CUM.ParseEntity(str, own)

end

function CUM.ParsePlayerOrEnt(str, own)
	local ent = CUM.ParsePlayer(str)
	local isply = true

	if not ent then
		ent = CUM.ParseEntity(str, own)
		isply = false
	end

	if not IsValid(ent) then return false, false end

	return ent, isply
end

local function SortArgs(cmd)


end

function cmdfuncs:AddPlayerArg(opt, def, desc, forceguess)
	opt = opt or false
	if isstring(def) then desc = def def = nil end

	self.Args[#self.Args + 1] = {type = "Player", opt = opt, nicetype = "Player", parse = function(s, ...)

		local parse = isstring(s) and CUM.ParsePlayer(s)
		local isself = (s=="^" and self.Runner)
		local opt = (not isstring(s) and opt and self.Runner)

		local out = {}

		if ((not parse and not isself) or forceguess) and def then
			out = {eval(def, s, ...)}

			if out[1]=="^" then out[1] = self.Runner return out end
		end

		return parse or isself or out or opt or "err", "Didn't find player! (" .. ((isstring(s) and s) or "???????wtf") .. ")"
	end, desc = desc}
	SortArgs(self)
	return self
end

function cmdfuncs:AddFullArg()

	self.Args[#self.Args + 1] = {type = "string", full = true, nicetype = false}
	SortArgs(self)

	return self
end

function cmdfuncs:SetPerms(perms)
	if isstring(perms) then
		table.insert(self.Permissions, perms)
	else
		table.Merge(self.Permissions, perms)
	end

	return self
end

function cmdfuncs:AddStringArg(opt, desc)
	opt = opt or false

	self.Args[#self.Args + 1] = {type = "string", opt = opt, nicetype = "Text", desc = desc}
	SortArgs(self)
	return self
end

function cmdfuncs:AddNumberArg(opt, def, desc)
	if isnumber(opt) then def = opt opt = true end
	opt = opt or false

	self.Args[#self.Args + 1] = {type = "number", opt = opt, nicetype = "Number", parse = function(s, ...)
		return tonumber(s) or tonumber(eval(def, ...)) or 0
	end, desc = desc}

	SortArgs(self)
	return self
end

function cmdfuncs:AddBoolArg(opt, def, desc)
	opt = opt or false

	self.Args[#self.Args + 1] = {type = "boolean", opt = opt, nicetype = "Boolean (true/false)", parse = function(s, ...) return CUM.ParseBool(s) or eval(def, ...) end, desc = desc}
	SortArgs(self)
	return self
end

local txColor = Color(160, 180, 220)

local function checkcol(tbl, col)
	if tbl[#tbl+1] ~= col then
		tbl[#tbl+1] = col
		if IsColor(tbl[#tbl-1]) then table.remove(tbl, #tbl-1) end
	end
end

function cmdfuncs:AddCallerArg()
	self.RequiresCaller = true
	--self.Args[#self.Args + 1] = {type = "Player", opt = opt, nicetype = "Caller(filled)", parse = function(s) return self.Runner end}
	--SortArgs(self)
	return self
end

-- wtf is this awfulness

function CUM.ParseOutput(str, out, repargs, strs, plys, key, ply)
	if str:match("{(%d+)}") then
		local lastend = 0
		local str2 = str

		local lastcol

		str:gsub( "({%d+})", function( i )
			local num = tonumber(i:match("{(%d+)}"))
			local arg = repargs[num]
			local where, ends = str2:find(i)
			checkcol(out, txColor)
			local subbed = str2:sub(lastend+1, where-1)
			if #subbed >= 1 then
				out[#out + 1] = subbed
			end

			lastend = ends

			if not arg then return "" end

			local is_console = IsEntity(arg) and not IsValid(arg)

			if IsPlayer(arg) and num == 0 then
				-- player who the report is being delivered to
				checkcol(out, Color(100, 220, 100))
				lastcol = Color(100, 220, 100)
				out[#out + 1] = arg:Nick()

			elseif IsPlayer(arg) or is_console then
				if is_console then
					checkcol(out, CUM.InvalidCallerColor)
					lastcol = CUM.InvalidCallerColor

					out[#out + 1] = CUM.InvalidCallerName

					if lastcol ~= txColor then
						checkcol(out, txColor)
						lastcol = txColor
					end
				else
					checkcol(out, team.GetColor(arg:Team()))
					lastcol = team.GetColor(arg:Team())

					out[#out + 1] = arg:Nick()

					if lastcol ~= txColor then
						checkcol(out, txColor)
						lastcol = txColor
					end
				end

			elseif tostring(arg) then
				arg = tostring(arg)
				local match = arg:match("<col=(.+)>") or arg:match("<color=(.+)")
				local where, ends = arg:find("<col=.+>")
				if not where and match then
					where, ends = arg:find("<color=.+>")
				end
				if match then
					local r,g,b = match:match("(%d+),(%d+),(%d+)")
					out[#out + 1] = Color(r or 0, g or 0, b or 0)
					lastCol = out[#out]
				end

				out[#out + 1] = arg:sub((ends or 0) + 1, #arg)
			end

			return ""
		end )

		if lastcol ~= txColor then
			checkcol(out, txColor)
			lastCol = txColor
		end


		out[#out + 1] = str2:sub(lastend+1, #str)

		strs[key] = out

		plys[key] = {}
		plys[key][1] = ply
	end
end

function cmdfuncs:_DoReport(...)
	local repargs = {...}

	local receipts
	local recName = self.ReportRecName

	if recName then
		receipts = CUM.Receipts[recName]
		if not receipts then
			CUM.Log("Invalid name for recepients in report func! (" .. recName .. ")\n"
				.. debug.traceback())
		end
	else
		receipts = player.GetAll()
	end

	receipts[#receipts + 1] = NULL -- console

	local strs = {}
	local plys = {}

	for _, ply in pairs(receipts) do
		local str, custtbl = self.ReportFunc(self, ply, ...)

		if not str or not isstring(str) then continue end

		if custtbl then table.Merge(repargs, custtbl) end

		local key = str .. table.ToString(repargs)

		local tbl = {}

		if strs[key] then
			tbl = strs[key]
			plys[key][#plys[key] + 1] = ply
		else
			CUM.ParseOutput(str, tbl, repargs, strs, plys, key, ply)
		end

		if ply == NULL then
			MsgC(unpack(tbl))
			MsgC("\n")
		end
	end

	for k,v in pairs(strs) do
		net.Start("ChatAddText")
			net.WriteTable(v)
		net.Send(plys[k] or receipts or player.GetAll())
	end
end

function cmdfuncs:SetReportFunc(func, recname)
	self.ReportFunc = func
	self.ReportRecName = recname
	self.reportfunc = function(...) self._DoReport(...) end -- autorefresh

	return self
end

function cmdfuncs:AddEntityArg(opt, desc)
	local opt = opt or false

	self.Args[#self.Args + 1] = {type = "Entity", opt = opt, parse = CUM.ParseEntity, desc = desc}
	SortArgs(self)
	return self
end

function cmdfuncs:SetSilent(bool)

	bool = (bool==nil and true) or bool
	self.Silent = bool
	return self
end

function cmdfuncs:SetHiddenCaller(bool)

	bool = (bool==nil and true) or bool
	self.HideCaller = bool
	return self
end

function cmdfuncs:SetAdminLog(bool)
	bool = (bool == nil and true) or bool
	self.OnlyAdminsSee = bool
	return self
end

function cmdfuncs:SetDescription(str)
	self.Description = str
	return self
end

function CUM.AddCommand(str, func)
	local cat = "Uncategorized"

	if CUM.CurCat then
		cat = CUM.CurCat
	end

	local cmds = CUM.cmds
	local cmd = {}

	cmd.name = (isstring(str) and str) or str[1]
	cmd.func = func
	cmd.Args = {}
	cmd.Permissions = {"superadmin"}

	setmetatable(cmd, cmdmeta)

	CUM.Cats[cat] = CUM.Cats[cat] or {}

	if isstring(str) then

		cmds[str] = cmd
		CUM.Cats[cat][str] = str

	elseif istable(str) then

		for k,v in pairs(str) do

			if isstring(v) then
				cmds[v] = cmd
				CUM.Cats[cat][v] = v
			end

		end
	end

	return cmd
end

local prefix = "^[%./]"

local argsep = "[%s,]"

local argPtrn = "([.%S]+)[%s]*"
local quotarg = '[^\\](.+)"'
local quotes = '["\']'

function CUM.ParseArgs(str)
	local args = {}

	if str:find(quotes) then
		local seps = {}

		for s in string.gmatch(str, argsep) do
			local pos = seps[#seps] or 0

			local where, ended, txt = string.find(str, s, pos + 1, true)
			if not where then continue end

			seps[#seps+1] = where
		end

		local str2 = str

		for s in string.gmatch(str, quotarg) do

			local s2 = s:gsub("\\\"", [["]])

			local num = 1
			local at, ended = str2:find(string.PatternSafe(s))

			for k,v in pairs(seps) do

				if at < v and ended > v then
					seps[k] = nil  --within the arg; remove it
					continue
				end


				if at > v then
					num = num + 1
				end
			end
			args[num] = s2

			str = str:gsub(argsep .. [[*"]] .. string.PatternSafe(s) .. [["]], "")
		end

		for s in string.gmatch(str, argPtrn) do
			local match = s:match(quotarg) or s:match(quotes)

			if match then str:gsub(match, "") continue end

			local num = 1
			local at, ended = str2:find(string.PatternSafe(s))

			for k,v in pairs(seps) do
				if at > v then
					num = num + 1
				end
			end

			args[num] = s

		end

		args[#args + 1] = str2

		return args
	end

	for s in string.gmatch(str, argPtrn) do
		args[#args+1] = s
	end

	if #str > 0 then
		args[#args + 1] = str
	end

	return args
end

function CUM.MissingArgFormat(cmd, num)
	local form = "Argument #%d (type: %s) is missing and is not optional.\n(Usage: %s)"
	local usage = ""
	for k,v in pairs(cmd.Args) do
		if v.nicetype == false then continue end
		usage = usage .. v.nicetype or v.type
		if next(cmd.Args, k) then usage = usage .. ", " end
	end

	return form:format(num, cmd.Args[num].type, usage)
end

function CUM.GetRunner()
	return CUM._Runner
end

function CUM.SendError(ply, str)
	ply = ply or CUM._Runner
	ply:ChatAddText(Color(250, 150, 20), str)
end

function CUM.HasPermissions(ply, to)
	local ug = ply:GetUserGroup()
	if not ug then return false end

	local perms = istable(to) and to or {to}

	for k,v in ipairs(perms) do
		if CAMI.UsergroupInherits(ug, v) then return true end
	end

	return BaseWars.IsDev(ply)
end

function CUM.Run(ply, cmd, argstr)
	argstr = argstr or ""

	local cmdtbl = CUM.cmds[cmd]
	if not cmdtbl then return end

	if IsValid(ply) and not CUM.HasPermissions(ply, cmdtbl.Permissions) then
		CUM.SendError(ply, "no permission")
		return
	end

	if cmdtbl.Executing then
		cmdtbl.Runner = false
		cmdtbl.Executing = false
		cmdtbl.ExecArgs = {}
	end

	local args = CUM.ParseArgs(argstr)

	local err = false
	local full = args[#args]

	args[#args] = nil

	local needsfull = false

	cmdtbl.Runner = ply
	CUM._Runner = ply

	cmdtbl.Executing = true
	cmdtbl.ExecArgs = {}
	cmdtbl.ReportArgs = {}

	local RETURN = cmdtbl.Silent and "" or nil

	--[[if not cmdtbl.HideCaller then
		cmdtbl.ReportArgs[0] = ply
	end]]

	local opts = 0

	for k,v in ipairs(cmdtbl.Args) do --preparse optional args & shift optional to required
		local arg = args[k]

		if v.opt then opts = opts + 1 end

		-- required arg missing
		if not arg and not v.opt then
			-- take last optional arg and make it the new required arg
			if args[k - 1] and cmdtbl.Args[k-1].opt then
				arg = args[k - 1]
				args[k - 1] = nil
				cmdtbl.ExecArgs[k - 1] = nil
				cmdtbl.ReportArgs[k - 1] = nil
			else
				local err = CUM.MissingArgFormat(cmdtbl, k)
				CUM.SendError(ply, err)

				return RETURN
			end
		end

		cmdtbl.ExecArgs[k] = arg
	end

	local add = 0

	for k,v in ipairs(cmdtbl.Args) do --fill up and parse execargs
		local arg = cmdtbl.ExecArgs[k]

		if v.full then
			needsfull = k
		end

		if v.parse then
			local ret, errstr = v.parse(arg, unpack(cmdtbl.ExecArgs))

			if ret=="err" and isstring(errstr) then
				CUM.SendError(ply, errstr)
				err = errstr
				break
			end

			if istable(ret) then
				for _,v in pairs(ret) do

					if v=="err" and isstring(errstr) then
						CUM.SendError(ply, errstr)
						err = errstr
						return RETURN
					end

					cmdtbl.ExecArgs[k + add] = v
					add = add + 1
				end
				add = add - 1
			else
				cmdtbl.ExecArgs[k + add] = ret
			end
		end

	end

	if err then return RETURN end

	if needsfull then
		table.insert(cmdtbl.ExecArgs, needsfull, full)
	end

	local caller = cmdtbl.RequiresCaller

	if caller then
		table.insert(cmdtbl.ExecArgs, 1, ply)
	end

	local ok, err = pcall(cmdtbl.func, ply, unpack(cmdtbl.ExecArgs))

	if not ok then
		CUM.Log("Error! %s", err)
		return
	end

	if cmdtbl.reportfunc and err ~= false then

		table.Merge(cmdtbl.ReportArgs, cmdtbl.ExecArgs)
		table.insert(cmdtbl.ReportArgs, 1, ply)

		if not IsValid(cmdtbl.ReportArgs[0]) then
			cmdtbl.ReportArgs[0] = CUM.InvalidCallerName
		end

		local ok, err = pcall(cmdtbl.reportfunc, cmdtbl, unpack(cmdtbl.ReportArgs))

		if not ok then
			print("[CUM] Report Error! :", err)
		end
	end

	cmdtbl.Runner = nil
	CUM._Runner = nil

	cmdtbl.Executing = false
	cmdtbl.ExecArgs = {}
	return RETURN
end

hook.Add("PlayerSay", "CUM.Commands", function(ply, str)
	if str:match(prefix) then
		local cmd = str:match(prefix .. "(%w+)")
		local argstr = str:gsub(prefix .. "(%w+)%s-", "")

		local ret = CUM.Run(ply, cmd, argstr)
		if ret then return ret end
	end
end)

concommand.Add("CUM", function(ply, _, argt, argstr)
	if not argt[1] then return end

	argstr = argstr:sub(#argt[1] + 2):match("%s*(.+)")

	CUM.Run(ply, argt[1], argstr)
end)
