


local function inc(fld)
	local fmt = "%s/%s_%s_ext.lua"
	include(fmt:format(fld, "sh", fld))
	include(fmt:format(fld, Rlm(true), fld))
end

inc("seed")
inc("leaf")
inc("cocaine")