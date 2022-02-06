local function init(force)
	local b = BaseWars.Bases and BaseWars.Bases.NW
	local reload = not not b

	if force and reload then
		for k,v in pairs(BaseWars.Bases.Bases) do
			v:Remove()
		end

		for k,v in pairs(BaseWars.Bases.Zones) do
			v:Remove()
		end

		if b and SERVER then
			b.Bases:Invalidate()
			b.Zones:Invalidate()
		end
	end

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

			BASE_CORENEW = 6,
			BASE_CORESAVE = 7,

			SZ = {
				base = 12,
				zone = 12
			}
		},

		Actions = {},

		SQL = {},			-- SV
		ZonePaints = {},	-- CL
	})

	BaseWars.Bases.Reset = Curry(init, true)

	if force and SERVER then
		for k,v in ipairs(ents.FindByClass("bw_zone_brush")) do
			v:Remove()
		end

		for k,v in ipairs(ents.FindByClass("bw_basecore")) do
			v:Remove()
		end
	end

	FInc.FromHere("bases/*.lua", FInc.SHARED, FInc.RealmResolver():SetDefault(true))

	if (force or not reload) and SERVER then
		-- either forced reload or initial; resync from sql
		BaseWars.Bases.SQLResync()
	end

	if force then
		for k,v in ipairs(GetAllPlayerInfos()) do
			v:SetBase(nil)
		end
	end
end

if CLIENT then
	LibItUp.OnLoaded("hud.lua", function()
		init()
		BaseWars.Bases.Reset = Curry(init, true)
	end)
else
	init()
	BaseWars.Bases.Reset = Curry(init, true)
end

