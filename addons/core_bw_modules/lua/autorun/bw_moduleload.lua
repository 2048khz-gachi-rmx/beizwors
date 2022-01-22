local path = "bw_modules/"

function IncludeBasewarsModules()
	local modules = 0

	local function incrementModule(fn)
		modules = modules + 1

		if MODULE.Name then
			hook.Run("BasewarsModuleLoaded", MODULE.Name)
		end
		LibItUp.MarkLoaded(fn)
	end

	local function moduleLoaded(p)
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

		FInc.Recursive(path .. "*.lua", FInc.SHARED, true, moduleLoaded, incrementModule)
		FInc.Recursive(path .. "server/*.lua", FInc.SERVER, nil, moduleLoaded, incrementModule)
		FInc.Recursive(path .. "map_edits/*.lua", FInc.SERVER, nil, moduleLoaded, incrementModule)
		FInc.Recursive(path .. "client/*.lua", FInc.CLIENT, nil, moduleLoaded, incrementModule)

	s = SysTime() - s

	Modules.Log("Loaded %d modules %s in %.2f s!", modules, rlm, s )

	MODULE = {} -- autorefresh support
end

if EntityInitted then
	IncludeBasewarsModules()
end