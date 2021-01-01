local path = "bw_modules/"

function IncludeBasewarsModules()
	local modules = 0

	local function incrementModule()
		modules = modules + 1
		print("loaded module:", MODULE.Name)

		if MODULE.Name then
			hook.Run("BasewarsModuleLoaded", MODULE.Name)
		end

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

		FInc.Recursive(path .. "*.lua", _SH, true, moduleLoaded, incrementModule)
		FInc.Recursive(path .. "server/*.lua", _SV, nil, moduleLoaded, incrementModule)
		FInc.Recursive(path .. "client/*.lua", _CL, nil, moduleLoaded, incrementModule)

	s = SysTime() - s

	Modules.Log("Loaded %d modules %s in %.2f s!", modules, rlm, s )

	MODULE = {} -- autorefresh support
end

if EntityInitted then
	IncludeBasewarsModules()
end