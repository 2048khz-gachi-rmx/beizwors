local path = "bw_modules/"

function IncludeBasewarsModules()
	local modules = 0

	local function endModule(fn, forced)
		modules = modules + 1

		MODULE.LoadPath = fn

		if not MODULE.DeferredEnd or forced then
			if MODULE.Name then
				hook.Run("BasewarsModuleLoaded", MODULE.Name, MODULE)
			end
			LibItUp.MarkLoaded(fn)
		end
	end

	function BaseWars.GetModuleLoader(nm)
		local md = MODULE
		if not md then
			errorNHf("Can't get a module loader outside of a module!")
			return BlankFunc
		end

		if not md.Name and not nm then
			errorNHf("Can't get a module loader of an unnamed module!")
			return
		end

		md.Name = nm or md.Name
		md.DeferredEnd = true

		local gee = _G

		return function()
			local pre = gee.MODULE
			gee.MODULE = md
				endModule(md.LoadPath, true)
			gee.MODULE = pre
		end
	end

	local function beginModule(p)
		if p:match("_ext$") or p:match("_ext_") then
			return false, false
		end
		MODULE = {}
	end

	local rlm = Realm(true, true)

	Modules = Modules or {}
	Modules.Log = Logger("BW-Modules", Colors.Sky)

	Modules.Register = function(name, col)
		return {name = name, col = col}
	end

	local s = SysTime()

		FInc.Recursive(path .. "*.lua", FInc.SHARED, beginModule, endModule)
		FInc.Recursive(path .. "server/*.lua", FInc.SERVER, beginModule, endModule)
		FInc.Recursive(path .. "map_edits/*.lua", FInc.SERVER, beginModule, endModule)
		FInc.Recursive(path .. "client/*.lua", FInc.CLIENT, beginModule, endModule)

	s = SysTime() - s

	Modules.Log("Loaded %d modules %s in %.2f s!", modules, rlm, s )

	MODULE = {} -- autorefresh support
end

if EntityInitted then
	IncludeBasewarsModules()
end