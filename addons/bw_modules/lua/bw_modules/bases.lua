

if BaseWars.Bases then
	local b = BaseWars.Bases.NW
	b.Bases:Invalidate()
	b.Zones:Invalidate()

	b.Bases = Networkable("bw_bases_bases")
	b.Zones = Networkable("bw_bases_zones")
end


local function init(force)
	BaseWars.Bases = (not force and BaseWars.Bases) or Emitter.Make({
		-- data populated from base_sql_sv
		Zones = {},	
		Bases = {},

		-- objects from base_zone
		Zone = Emitter:callable(),
		Base = Emitter:callable(),

		MarkTool = nil, -- gets filled in areamark/ folder

		Log = Logger("BW-Bases" .. Rlm(), CLIENT and Color(55, 205, 135) or Color(200, 50, 120)),	-- bw18 throwback

		NW = {
			Bases = Networkable("bw_bases_bases"),
			Zones = Networkable("bw_bases_zones"),
			PlayerData = SERVER and {} or nil, 	-- defined in base_nw_*
												-- serverside, a table ; clientside, the nw object itself
			BASE_NEW = 0,
			BASE_YEET = 1,

			ZONE_NEW = 2,
			ZONE_EDIT = 3,
			ZONE_YEET = 4,

			BASE_EDIT = 5,

			SZ = {
				base = 12,
				zone = 12
			}
		},

		SQL = {},			-- SV
		ZonePaints = {},	-- CL
	})


	FInc.FromHere("bases/*.lua", _SH, true, FInc.RealmResolver():SetDefault(true))
end

init()
BaseWars.Bases.Reset = Curry(init, true)
